import 'package:flutter_test/flutter_test.dart';
import 'package:prism_engine/engine/finance.dart';
import 'package:prism_engine/models/models.dart';

import 'helpers.dart';

ParentProfile parent({int savings = 0, LoanComfort loan = LoanComfort.none, int emi = 0, int income = 300000}) => ParentProfile(
      familyCode: 'X',
      annualIncomeINR: income,
      savingsForEducationINR: savings,
      maxMonthlyEmiINR: emi,
      expectedSalaryAt25INR: 500000,
      loanComfort: loan,
      riskAppetite: 0.5,
      preferredCareerIds: const [],
      preferredYearsToEarning: 5,
      relocationAcceptance: Mobility.state,
      completedAt: DateTime(2026),
    );

void main() {
  final seed = loadSeed();
  final student = persona(seed, 'arjun').student;
  final mbbs = seed.careerById['doctor-mbbs']!;

  test('total cost follows the formula', () {
    final r = mbbs.routes.first;
    expect(r.totalCostINR, (r.tuitionPerYearINR + r.livingPerYearINR) * r.years + r.coachingINR + r.examFeesINR);
  });

  test('zero savings and no loan: private MBBS is not viable', () {
    final res = financialConstraintSolver(mbbs, student, parent(), seed.scholarships).result;
    final private = res.allRoutes.firstWhere((r) => r.routeId == 'private');
    expect(private.feasibility, lessThan(0.6));
    expect(private.viable, isFalse);
  });

  test('more savings never lowers feasibility', () {
    final low = financialConstraintSolver(mbbs, student, parent(savings: 100000), seed.scholarships).result.best;
    final high = financialConstraintSolver(mbbs, student, parent(savings: 5000000), seed.scholarships).result.best;
    expect(high.feasibility, greaterThanOrEqualTo(low.feasibility));
    expect(high.feasibility, 1.0);
  });

  test('loan capacity respects the comfort limit', () {
    final res = financialConstraintSolver(mbbs, student, parent(loan: LoanComfort.moderate, emi: 100000), seed.scholarships).result;
    for (final r in res.allRoutes) {
      expect(r.loanCapacityINR, lessThanOrEqualTo(750000));
    }
  });

  test('ROI normalisation: -1 → 0, 2 → 0.5, monotonic', () {
    expect(roiNormalized(-1), 0);
    expect(roiNormalized(2), closeTo(0.5, 1e-9));
    expect(roiNormalized(8), greaterThan(roiNormalized(3)));
  });

  test('cheapest viable route is chosen when one exists', () {
    final res = financialConstraintSolver(seed.careerById['software-engineer']!, student, parent(savings: 3000000), seed.scholarships).result;
    final viable = res.allRoutes.where((r) => r.viable).toList()..sort((a, b) => a.totalCostINR.compareTo(b.totalCostINR));
    expect(res.best.routeId, viable.first.routeId);
  });
}
