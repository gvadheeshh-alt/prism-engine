import 'dart:math' as math;

import '../models/models.dart';
import 'format.dart';
import 'math_utils.dart';
import 'scholarships.dart';

/// Tunable assumptions for the Financial Constraint Solver (all shown on the Methodology screen).
class FinanceParams {
  final double discountRate = 0.08; // for NPV
  final double loanAnnualRate = 0.09; // education loan interest
  final int loanMonths = 84; // 7-year repayment
  final double emiShareOfSalary = 0.35; // EMI must be ≤ 35% of starting monthly salary
  final int baselineSalaryINR = 180000; // what the student might earn without this degree
  final double baselineGrowth = 0.05;
  final double scholarshipCertainty = 0.5; // scholarships are not guaranteed: count 50%
  final int maxSchemesCounted = 2; // never stack more than 2 schemes
  final Map<LoanComfort, int> loanLimitINR = const {
    LoanComfort.none: 0,
    LoanComfort.moderate: 750000,
    LoanComfort.high: 2000000,
  };
  const FinanceParams();
}

const kFinance = FinanceParams();

/// Annual salary in working year t (1..10), linear between start → year 5 → year 10.
double salaryInWorkYear(Career c, int t) {
  if (t <= 5) return c.startingSalaryINR + (c.year5SalaryINR - c.startingSalaryINR) * (t - 1) / 4;
  return c.year5SalaryINR + (c.year10SalaryINR - c.year5SalaryINR) * (t - 5) / 5;
}

/// Rough salary at age ~25 (2 years into work).
double salaryAt25(Career c) => c.startingSalaryINR + (c.year5SalaryINR - c.startingSalaryINR) * 0.4;

double _baseline(int yearFromNow, FinanceParams f) =>
    f.baselineSalaryINR * math.pow(1 + f.baselineGrowth, yearFromNow - 1).toDouble();

RouteFinance solveRoute(Career c, EducationRoute r, ParentProfile? p, List<ScholarshipMatch> matches,
    {FinanceParams f = kFinance}) {
  final tc = r.totalCostINR.toDouble();
  final years = r.years;

  // Scholarships: top-2 schemes, capped at tuition, counted at 50% certainty.
  final perYear = matches.take(f.maxSchemesCounted).fold<int>(0, (s, m) => s + m.scholarship.amountINR);
  final scholarship =
      f.scholarshipCertainty * math.min(perYear * years, r.tuitionPerYearINR * years).toDouble();

  // Loan capacity: PV of an affordable EMI, capped by the family's comfort level.
  double emi = f.emiShareOfSalary * c.startingSalaryINR / 12;
  if (p != null && p.maxMonthlyEmiINR > 0) emi = math.min(emi, p.maxMonthlyEmiINR.toDouble());
  final comfort = p?.loanComfort ?? LoanComfort.moderate;
  final pvLoan = presentValueOfAnnuity(emi, f.loanAnnualRate / 12, f.loanMonths);
  final loan = math.min(f.loanLimitINR[comfort]!.toDouble(), pvLoan);

  final savings = (p?.savingsForEducationINR ?? 0).toDouble();
  final funding = savings + scholarship + loan;
  final feasibility = tc <= 0 ? 1.0 : clamp01(funding / tc);

  // ROI vs. baseline over study years + 10 working years, discounted.
  double npvCareer = 0, npvBase = 0;
  for (var t = 1; t <= 10; t++) {
    npvCareer += salaryInWorkYear(c, t) / math.pow(1 + f.discountRate, years + t);
  }
  for (var k = 1; k <= years + 10; k++) {
    npvBase += _baseline(k, f) / math.pow(1 + f.discountRate, k);
  }
  final roi = tc <= 0 ? 0.0 : (npvCareer - npvBase - tc) / tc;

  // Payback: first working year when cumulative extra earnings cover the total cost.
  double? payback;
  double cum = 0;
  for (var t = 1; t <= 10; t++) {
    cum += salaryInWorkYear(c, t) - _baseline(years + t, f);
    if (cum >= tc) {
      payback = t.toDouble();
      break;
    }
  }

  return RouteFinance(
    routeId: r.id,
    label: r.label,
    tier: r.tier,
    years: years,
    totalCostINR: tc.round(),
    savingsINR: savings.round(),
    scholarshipINR: scholarship.round(),
    loanCapacityINR: loan.round(),
    feasibility: feasibility,
    roi: roi,
    paybackYears: payback,
  );
}

class FinanceSolution {
  final FinanceResult result;
  final Trace trace;
  const FinanceSolution(this.result, this.trace);
}

/// Stage 2, step 3: Financial Constraint Solver.
/// Evaluates every education route for a career and picks the cheapest viable one (F ≥ 0.6),
/// or the most feasible one when none is viable. Students already in college (UG/PG) prefer
/// online/distance routes when one is viable.
FinanceSolution financialConstraintSolver(Career c, StudentVector s, ParentProfile? p, List<Scholarship> all,
    {FinanceParams f = kFinance}) {
  final matches = matchScholarships(s, p, all, career: c);
  final routes = [for (final r in c.routes) solveRoute(c, r, p, matches, f: f)];
  final viable = routes.where((r) => r.viable).toList()..sort((a, b) => a.totalCostINR.compareTo(b.totalCostINR));

  RouteFinance best;
  final inCollege = s.context.level == StudyLevel.ug || s.context.level == StudyLevel.pg;
  final flexible = viable.where((r) => r.tier == RouteTier.online || r.tier == RouteTier.distance).toList();
  if (inCollege && flexible.isNotEmpty) {
    best = flexible.first;
  } else if (viable.isNotEmpty) {
    best = viable.first;
  } else {
    best = routes.reduce((a, b) => a.feasibility >= b.feasibility ? a : b);
  }

  final result = FinanceResult(
    cheapestViableRouteId: viable.isEmpty ? null : viable.first.routeId,
    best: best,
    allRoutes: routes,
    scholarships: matches,
  );
  final trace = Trace(
    metric: 'Feasibility & ROI',
    formula: 'F = min(1, (savings + scholarship + loan capacity) / total cost)\n'
        'Loan capacity = min(loan limit, PV of EMI ≤ min(parent max EMI, 35% of starting monthly salary) over 7 yrs @ 9%)\n'
        'ROI = (NPV of 10-yr salary − NPV of baseline earnings − total cost) / total cost, discount 8%',
    inputs: {
      'Route': best.label,
      'Total cost': inr(best.totalCostINR),
      'Savings': inr(best.savingsINR),
      'Expected scholarship (50% certainty)': inr(best.scholarshipINR),
      'Loan capacity': inr(best.loanCapacityINR),
      'ROI': roiText(best.roi),
      'Payback (working years)': best.paybackYears?.toStringAsFixed(0) ?? 'over 10',
    },
    value: best.feasibility,
  );
  return FinanceSolution(result, trace);
}

/// Highest return that still counts. Very cheap courses (e.g. a short online certificate) can show a
/// return of 100x their cost, which would otherwise swamp every other factor.
const double roiCap = 6;

/// Maps ROI (−1..∞) to 0..1 with diminishing returns: (min(ROI, 6) + 1) / (min(ROI, 6) + 4).
/// ROI −1 → 0, ROI 2 → 0.5, ROI 6 or more → 0.7.
double roiNormalized(double roi) {
  if (roi <= -1) return 0;
  final capped = roi > roiCap ? roiCap : roi;
  return clamp01((capped + 1) / (capped + 4));
}
