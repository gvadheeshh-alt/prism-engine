"""Simulates many quiz-takers and reports how varied the top recommendations are.
Uses the Python reference engine in tools/engine_reference.py."""
import importlib.util, io, contextlib, random, collections, sys, os
spec = importlib.util.spec_from_file_location("ref", os.path.join(os.path.dirname(__file__), "engine_reference.py"))
ref = importlib.util.module_from_spec(spec)
with contextlib.redirect_stdout(io.StringIO()): spec.loader.exec_module(ref)

RIASEC = ["realistic","investigative","artistic","social","enterprising","conventional"]
APT = ["numerical","logical","verbal","spatial","creative"]
WS = ["openness","conscientiousness","collaboration","riskTolerance"]
STREAMS = ["sciencePcm","sciencePcb","sciencePcmb","commerce","humanities"]

def student(rng, acquiescence):
    dom = rng.sample(RIASEC, rng.choice([1, 2]))
    d = {}
    for t in RIASEC:
        true = 0.2 + rng.random() * 0.25 + (0.45 if t in dom else 0)
        d[t] = min(1, true * (1 - acquiescence) + acquiescence * 0.85 + rng.gauss(0, 0.05))
    for t in APT: d[t] = min(1, max(0, 0.35 + rng.random() * 0.55))
    for t in WS: d[t] = min(1, max(0, 0.3 + rng.random() * 0.6))
    ctx = dict(level=rng.choice(["class10","class12","class12","ug"]), stream=rng.choice(STREAMS), marksBand="b75to90",
               state="Tamil Nadu", district="Chennai", mobility=rng.choice(["state","india"]), dreamCareerIds=[])
    return dict(dims=d, context=ctx), dom

def parent(rng):
    return dict(annualIncomeINR=rng.choice([300000,650000,1150000]), savingsForEducationINR=rng.choice([100000,300000,800000]),
                maxMonthlyEmiINR=10000, loanComfort="moderate", riskAppetite=rng.random()*0.6, preferredCareerIds=[],
                expectedSalaryAt25INR=600000, preferredYearsToEarning=6, relocationAcceptance="state", firstGenerationLearner=False)

def run(rank_fn, n=600, seed=1, label=""):
    rng = random.Random(seed)
    top1, top3 = collections.Counter(), collections.Counter()
    match_dom = 0
    for _ in range(n):
        st, dom = student(rng, acquiescence=rng.choice([0.0, 0.3, 0.5]))
        ranked = rank_fn(st, parent(rng))
        top1[ranked[0]] += 1
        for c in ranked[:3]: top3[c] += 1
        # does the #1 career's strongest interest type match one of the student's dominant types?
        req = ref.CAR[ranked[0]]["requirement"]
        if max(RIASEC, key=lambda t: req[t]) in dom: match_dom += 1
    print(f"== {label}: {len(top1)} different #1 careers out of {n} students")
    print("   most common #1:", ", ".join(f"{c} {v*100//n}%" for c, v in top1.most_common(6)))
    print(f"   #1 career matches the student's main interest type: {match_dom*100//n}%")
    return top1

def current_rank(st, pa):
    rows = []
    for c in ref.D:
        f = ref.fit(st["dims"], c); fin = ref.finance(st, pa, c); F = fin["F"]
        ctx = st["context"]
        if ctx["level"] in ["class11","class12","ug","pg"] and c["eligibleStreams"] and ctx["stream"] != "undecided" and ctx["stream"] not in c["eligibleStreams"]: F *= .3
        M = ref.market(st, c); roi = min(fin["roi"], 6); rn = max(0, (roi+1)/(roi+4)) if roi > -1 else 0
        rows.append((100*(.45*f+.2*M+.15*F+.2*rn), c["id"]))
    rows.sort(reverse=True)
    return [r[1] for r in rows]

if __name__ == "__main__":
    run(current_rank, label="engine")
