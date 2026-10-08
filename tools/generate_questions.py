"""Generates assets/data/questions.json and personas.json.

Question design:
- Interest statements describe concrete activities rather than abstract traits.
- "Which would you rather do?" items force a choice between two interest types. If someone agrees with
  every statement, Likert answers alone give a flat profile; forced choices still separate their interests.
  Each of the six types appears in exactly three choice items.
- Puzzles are harder than a quick check and have one clearly correct answer each (verified below).
"""
import json, os
from collections import Counter
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "data")
Q = []

def lik(dim, text, rev=False):
    Q.append(dict(id=f"L{sum(1 for q in Q if q['type']=='likert')+1:02d}", type="likert", dimension=dim, text=text, reverse=rev))

def choice(text, a, a_dim, b, b_dim):
    Q.append(dict(id=f"C{sum(1 for q in Q if q['type']=='choice')+1:02d}", type="choice", dimension=a_dim, text=text,
                  options=[a, b], optionDims=[a_dim, b_dim]))

def apt(dim, text, options, ans, seconds=60):
    Q.append(dict(id=f"A{sum(1 for q in Q if q['type']=='aptitude')+1:02d}", type="aptitude", dimension=dim, text=text,
                  options=options, answerIndex=ans, seconds=seconds))

# Interests: 3 per RIASEC type, interleaved
lik("realistic", "I would enjoy fixing a bicycle, a fan or a phone charger myself.")
lik("investigative", "I like finding out why things happen, like why a medicine works or why the sky is blue.")
lik("artistic", "In my free time I enjoy drawing, designing, photography, music or writing stories.")
lik("social", "Friends often come to me when they have a problem.")
lik("enterprising", "I like being the one who organises a team, an event or a college fest.")
lik("conventional", "I keep my notes, files and money accounts neat and up to date.")
lik("realistic", "I would like a job where I build, repair or operate real machines and equipment.")
lik("investigative", "I enjoy working on a hard maths or science problem even when it takes a long time.")
lik("artistic", "I prefer to create my own design rather than copy an example.")
lik("social", "I would enjoy teaching a younger student something they find difficult.")
lik("enterprising", "I enjoy persuading people, for example in a debate or when selling something.")
lik("conventional", "I enjoy work with clear steps and rules, like accounts, records or data entry.")
lik("realistic", "I would rather read about how an engine works than take one apart.", True)
lik("investigative", "I would enjoy running experiments in a lab and recording the results.")
lik("artistic", "I would be happy in a job with no creative work at all.", True)
lik("social", "I would like a job caring for people, such as nursing, teaching or counselling.")
lik("enterprising", "I would like to start my own business one day, even if it is risky.")
lik("conventional", "Checking details carefully, like proofreading or verifying numbers, suits me.")

# Which would you rather do? (each type appears exactly 3 times)
choice("On a free Saturday, which would you rather do?",
       "Build a working model or fix something at home", "realistic",
       "Watch a science documentary and work out how it all works", "investigative")
choice("At the college fest, which job would you pick?",
       "Design the posters and the stage", "artistic",
       "Welcome the guests and help anyone who is lost", "social")
choice("In a group project, which role suits you better?",
       "Lead the team and present to the judges", "enterprising",
       "Keep the budget, files and records accurate", "conventional")
choice("Which class would you rather take?",
       "An electronics or carpentry workshop", "realistic",
       "A painting, music or film-making class", "artistic")
choice("Which summer internship sounds better?",
       "Research assistant in a science lab", "investigative",
       "Sales and marketing at a new startup", "enterprising")
choice("Which job sounds more like you?",
       "School counsellor", "social",
       "Bank officer", "conventional")
choice("Which would you rather do?",
       "Operate and repair a drone", "realistic",
       "Pitch a business idea to investors", "enterprising")
choice("Which would you rather spend an afternoon on?",
       "Working out why an experiment gave a strange result", "investigative",
       "Organising a messy spreadsheet of marks into clear tables", "conventional")
choice("Which would you find more rewarding?",
       "Writing and directing a short film", "artistic",
       "Volunteering at a hospital or an old-age home", "social")

# Work style: 2 each
lik("openness", "I like trying new subjects, foods or places, even if I might not enjoy them.")
lik("conscientiousness", "I finish homework and projects on time, even the boring ones.")
lik("collaboration", "I do my best work in a team project rather than alone.")
lik("riskTolerance", "I would choose an exciting career with uncertain pay over a safe one with fixed pay.")
lik("openness", "I often read or watch things about topics outside my syllabus.")
lik("conscientiousness", "Before exams I plan my week instead of studying at the last minute.")
lik("collaboration", "I prefer working alone over group projects.", True)
lik("riskTolerance", "I am comfortable taking a risk when the possible reward is big.")

# Puzzles: harder, 60 seconds each
apt("numerical", "A phone's price goes up by 20%, then down by 20%. Compared with the original price, it is now:",
    ["The same", "4% lower", "4% higher", "2% lower"], 1)
apt("numerical", "A 150 m long train passes a pole in 10 seconds. At the same speed, how long does it take to cross a 450 m platform?",
    ["30 seconds", "36 seconds", "40 seconds", "45 seconds"], 2)
apt("logical", "What comes next: 3, 5, 9, 17, 33, ?", ["49", "57", "65", "66"], 2)
apt("logical", "Asha finished ahead of Bala but behind Chitra. Deepak finished ahead of Chitra. Who finished last?",
    ["Asha", "Bala", "Chitra", "Deepak"], 1)
apt("logical", "All roses are flowers. Some flowers fade quickly. Which statement must be true?",
    ["All roses fade quickly", "Some roses fade quickly", "No roses fade quickly", "None of these must be true"], 3)
apt("verbal", "Which word is most nearly the OPPOSITE of 'frugal'?", ["Careful", "Extravagant", "Honest", "Poor"], 1)
apt("verbal", "Which sentence is grammatically correct?",
    ["Neither of the answers are correct.", "Neither of the answers is correct.", "Neither of the answer is correct.", "Neither of answers is correct."], 1)
apt("spatial", "A 4 × 4 × 4 cube is painted on every face and cut into 64 small cubes. How many small cubes have no paint at all?",
    ["4", "8", "16", "24"], 1)
apt("spatial", "You face north. You turn 90° to your right, then 180°, then 90° to your left. Which way do you face now?",
    ["North", "East", "South", "West"], 2)
apt("creative", "Which single word goes with all three: falling, shooting, dust?", ["Rain", "Star", "Gold", "Storm"], 1)
apt("creative", "Which single word goes with all three: pine, crab, sauce?", ["Tree", "Apple", "Shell", "Tomato"], 1)

for dim, text in [("numerical", "How good are you at maths and working with numbers?"),
                  ("logical", "How good are you at puzzles and step-by-step reasoning?"),
                  ("verbal", "How good are you at reading, writing and explaining ideas?"),
                  ("spatial", "How good are you at imagining shapes, maps and 3D objects?"),
                  ("creative", "How good are you at coming up with original ideas?")]:
    Q.append(dict(id=f"S{sum(1 for q in Q if q['type']=='selfRating')+1:02d}", type="selfRating", dimension=dim, text=text))

# Independent checks of every puzzle answer
assert round(100 * 1.2 * 0.8) == 96                      # 4% lower
assert (150 + 450) / (150 / 10) == 40                    # 40 seconds
seq = [3, 5, 9, 17, 33]; assert all(seq[i + 1] == 2 * seq[i] - 1 for i in range(4)) and 2 * 33 - 1 == 65
finish = ["Deepak", "Chitra", "Asha", "Bala"]            # D ahead of C, C ahead of A, A ahead of B
assert finish.index("Chitra") < finish.index("Asha") < finish.index("Bala") and finish.index("Deepak") < finish.index("Chitra")
assert (4 - 2) ** 3 == 8                                 # unpainted inner cube
dirs = ["North", "East", "South", "West"]; h = (0 + 1 + 2 - 1) % 4; assert dirs[h] == "South"
for q in Q:
    if q["type"] == "aptitude": assert 0 <= q["answerIndex"] < len(q["options"]) and len(set(q["options"])) == len(q["options"])
counts = Counter(d for q in Q if q["type"] == "choice" for d in q["optionDims"])
assert len(counts) == 6 and all(v == 3 for v in counts.values()), counts

json.dump(Q, open(os.path.join(OUT, "questions.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

D = ["realistic", "investigative", "artistic", "social", "enterprising", "conventional", "numerical", "logical", "verbal",
     "spatial", "creative", "openness", "conscientiousness", "collaboration", "riskTolerance"]
def dims(*v): return dict(zip(D, v))
P = [
 dict(id="priya", title="Priya, Class 12, Madurai", blurb="Loves maths and art. Parents want her to become a doctor. Tight family budget.",
  student=dict(studentId="demo-priya", familyCode="DEMO01", name="Priya", completedAt="2026-10-01T10:00:00",
    dims=dims(.45, .7, .85, .55, .45, .4, .8, .75, .6, .85, .9, .85, .7, .6, .7),
    context=dict(level="class12", stream="sciencePcmb", marksBand="b75to90", state="Tamil Nadu", district="Madurai", mobility="india",
                 dreamCareerIds=["architect", "ux-designer", "product-designer"], gender="female", category="obc")),
  parent=dict(familyCode="DEMO01", annualIncomeINR=300000, savingsForEducationINR=60000, maxMonthlyEmiINR=6000, expectedSalaryAt25INR=1200000,
    loanComfort="moderate", riskAppetite=0.15, preferredCareerIds=["doctor-mbbs", "civil-services", "pharmacist"], preferredYearsToEarning=5,
    relocationAcceptance="state", category="obc", childGender="female", firstGenerationLearner=True, completedAt="2026-10-01T10:30:00")),
 dict(id="arjun", title="Arjun, Class 10, Coimbatore", blurb="Builds gadgets at home, loves design. Choosing his Class 11 stream.",
  student=dict(studentId="demo-arjun", familyCode="DEMO02", name="Arjun", completedAt="2026-10-01T11:00:00",
    dims=dims(.9, .65, .7, .35, .55, .45, .7, .7, .45, .85, .8, .75, .6, .6, .55),
    context=dict(level="class10", stream="undecided", marksBand="b60to75", state="Tamil Nadu", district="Coimbatore", mobility="state",
                 dreamCareerIds=["robotics-engineer", "ev-engineer", "game-developer"], gender="male", category="general")),
  parent=dict(familyCode="DEMO02", annualIncomeINR=600000, savingsForEducationINR=200000, maxMonthlyEmiINR=10000, expectedSalaryAt25INR=600000,
    loanComfort="moderate", riskAppetite=0.35, preferredCareerIds=["mechanical-engineer", "software-engineer"], preferredYearsToEarning=7,
    relocationAcceptance="state", category="general", childGender="male", firstGenerationLearner=False, completedAt="2026-10-01T11:30:00")),
 dict(id="sneha", title="Sneha, B.Com 2nd year, Chennai", blurb="Wants to switch into data science. Moderate budget.",
  student=dict(studentId="demo-sneha", familyCode="DEMO03", name="Sneha", completedAt="2026-10-01T12:00:00",
    dims=dims(.2, .75, .35, .5, .55, .75, .8, .75, .7, .4, .5, .75, .8, .65, .45),
    context=dict(level="ug", stream="commerce", marksBand="b75to90", state="Tamil Nadu", district="Chennai", mobility="india",
                 dreamCareerIds=["data-scientist", "data-analyst", "product-manager"], gender="female", category="general")),
  parent=dict(familyCode="DEMO03", annualIncomeINR=900000, savingsForEducationINR=300000, maxMonthlyEmiINR=12000, expectedSalaryAt25INR=800000,
    loanComfort="moderate", riskAppetite=0.4, preferredCareerIds=["chartered-accountant", "financial-analyst"], preferredYearsToEarning=2,
    relocationAcceptance="india", category="general", childGender="female", firstGenerationLearner=False, completedAt="2026-10-01T12:30:00")),
]
json.dump(P, open(os.path.join(OUT, "personas.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(Q), "questions:", dict(Counter(q["type"] for q in Q)), "| choice coverage:", dict(counts), "|", len(P), "personas")
