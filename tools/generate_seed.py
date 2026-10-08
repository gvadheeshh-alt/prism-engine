"""Generates assets/data/*.json. ALL values are ILLUSTRATIVE demo data, not official statistics.
Edit the tables below and re-run:  python tools/generate_seed.py"""
import json, os
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "data")
DIMS = ["realistic","investigative","artistic","social","enterprising","conventional",
        "numerical","logical","verbal","spatial","creative",
        "openness","conscientiousness","collaboration","riskTolerance"]
L = 100000  # 1 lakh

REGIONS = [  # id, name, state, lat, lng, metro, abroad
 ("chennai","Chennai","Tamil Nadu",13.08,80.27,True,False),
 ("coimbatore","Coimbatore","Tamil Nadu",11.02,76.96,False,False),
 ("madurai","Madurai","Tamil Nadu",9.93,78.12,False,False),
 ("tiruppur","Tiruppur","Tamil Nadu",11.11,77.34,False,False),
 ("bengaluru","Bengaluru","Karnataka",12.97,77.59,True,False),
 ("hyderabad","Hyderabad","Telangana",17.39,78.49,True,False),
 ("pune","Pune","Maharashtra",18.52,73.86,False,False),
 ("mumbai","Mumbai","Maharashtra",19.08,72.88,True,False),
 ("delhi-ncr","Delhi NCR","Delhi",28.61,77.21,True,False),
 ("kolkata","Kolkata","West Bengal",22.57,88.36,True,False),
 ("ahmedabad","Ahmedabad","Gujarat",23.02,72.57,False,False),
 ("kochi","Kochi","Kerala",9.93,76.27,False,False),
 ("abroad","Abroad (Gulf / EU / US)","Abroad",0,0,False,True),
]
RID = [r[0] for r in REGIONS]
DEMAND = {  # same order as REGIONS
 "tech":    [.8,.5,.25,.1,1,.9,.75,.7,.8,.45,.4,.45,.7],
 "mfg":     [.9,.85,.35,.5,.6,.5,.9,.5,.6,.35,.7,.3,.4],
 "infra":   [.7,.5,.4,.3,.8,.8,.7,.9,.9,.5,.6,.4,.6],
 "energy":  [.7,.6,.5,.4,.6,.5,.5,.5,.6,.3,.8,.3,.5],
 "health":  [.9,.7,.7,.3,.8,.8,.6,.8,.9,.7,.6,.7,.8],
 "pharma":  [.6,.4,.3,.2,.8,1,.6,.7,.5,.4,.8,.3,.6],
 "research":[.7,.4,.3,.1,.9,.6,.7,.6,.8,.5,.4,.4,.8],
 "media":   [.8,.3,.2,.1,.6,.9,.5,1,.7,.5,.3,.5,.5],
 "finance": [.7,.5,.3,.3,.8,.6,.6,1,.9,.6,.6,.4,.6],
 "govt":    [.7,.5,.5,.4,.6,.6,.5,.6,.9,.6,.5,.5,.1],
 "agri":    [.4,.8,.7,.5,.5,.6,.6,.3,.4,.5,.5,.5,.3],
 "textiles":[.5,.6,.4,1,.6,.3,.3,.7,.7,.4,.8,.2,.4],
}

def r(id,label,tier,years,tuition,living,coaching,fees,exams):
    return dict(id=id,label=label,tier=tier,years=years,tuitionPerYearINR=int(tuition),
                livingPerYearINR=int(living),coachingINR=int(coaching),examFeesINR=int(fees),entryExamIds=exams)
ROUTES = {
 "btech": lambda ex: [r("govt","B.Tech at a government college",'govt',4,.6*L,.72*L,1*L,3000,ex),
                      r("private","B.Tech at a private college",'private',4,2.5*L,1.2*L,.5*L,3000,ex),
                      r("lateral","Polytechnic diploma, then B.Tech (lateral entry)",'lateralEntry',6,.4*L,.48*L,0,1500,[])],
 "mbbs":  lambda ex: [r("govt","MBBS at a government medical college",'govt',6,.3*L,.8*L,1.5*L,2000,ex),
                      r("private","MBBS at a private medical college",'private',6,12*L,1.2*L,1.5*L,2000,ex),
                      r("abroad","MBBS abroad (FMGE/NExT required on return)",'private',6,5*L,2.5*L,.5*L,2000,ex)],
 "bds":   lambda ex: [r("govt","BDS at a government college",'govt',5,.4*L,.8*L,1*L,2000,ex),
                      r("private","BDS at a private college",'private',5,5*L,1.2*L,1*L,2000,ex)],
 "nursing":lambda ex:[r("govt","B.Sc Nursing, government college",'govt',4,.2*L,.6*L,0,1500,ex),
                      r("private","B.Sc Nursing, private college",'private',4,1.2*L,.9*L,0,1500,ex)],
 "bpharm":lambda ex: [r("govt","B.Pharm, government college",'govt',4,.3*L,.6*L,0,1500,ex),
                      r("private","B.Pharm, private college",'private',4,1.2*L,.9*L,0,1500,ex)],
 "bpt":   lambda ex: [r("govt","BPT, government college",'govt',5,.3*L,.7*L,0,1500,ex),
                      r("private","BPT, private college",'private',5,1.5*L,.9*L,0,1500,ex)],
 "psych": lambda ex: [r("govt","BA/B.Sc Psychology + MA, government college",'govt',5,.2*L,.6*L,0,1000,ex),
                      r("private","BA/B.Sc Psychology + MA, private college",'private',5,1.5*L,1*L,0,1000,ex)],
 "bsc":   lambda ex: [r("govt","B.Sc + M.Sc, government college",'govt',5,.2*L,.6*L,0,1000,ex),
                      r("private","B.Sc + M.Sc, private college",'private',5,1.2*L,.9*L,0,1000,ex)],
 "bsres": lambda ex: [r("govt","BS-MS at IISER / central institute",'govt',5,1*L,.6*L,.3*L,2000,ex),
                      r("private","B.Sc + M.Sc, private college",'private',5,1.2*L,.9*L,0,1000,ex)],
 "bsc_ds":lambda ex: [r("govt","B.Sc Data Science / Statistics, government college",'govt',3,.3*L,.6*L,0,1000,ex),
                      r("private","B.Sc Data Science, private college",'private',3,2*L,1*L,0,1000,ex),
                      r("online","Online BS in Data Science (study from home)",'online',4,.75*L,0,0,3000,[])],
 "analyst":lambda ex:[r("govt","B.Sc Statistics / B.Com, government college",'govt',3,.15*L,.6*L,0,1000,ex),
                      r("online","Online analytics certification + portfolio",'online',1,.4*L,0,0,0,[])],
 "pm":    lambda ex: [r("govt","B.Tech, then MBA at a government institute",'govt',6,2.5*L,.9*L,.5*L,5000,ex),
                      r("private","Degree, then MBA at a private institute",'private',6,4.5*L,1.2*L,.5*L,5000,ex)],
 "bdes":  lambda ex: [r("govt","B.Des at NID / IIT",'govt',4,2.2*L,.8*L,.5*L,3000,ex),
                      r("private","B.Des at a private design school",'private',4,4*L,1.2*L,.3*L,3000,ex)],
 "barch": lambda ex: [r("govt","B.Arch at a government college",'govt',5,.5*L,.72*L,.4*L,2500,ex),
                      r("private","B.Arch at a private college",'private',5,2.5*L,1.2*L,.4*L,2500,ex)],
 "nift":  lambda ex: [r("govt","B.Des (Fashion) at NIFT",'govt',4,3.3*L,1*L,.4*L,3000,ex),
                      r("private","Fashion design, private institute",'private',4,3*L,1.2*L,0,2000,ex)],
 "anim":  lambda ex: [r("private","B.Sc Animation & VFX, private college",'private',3,2*L,1*L,0,1000,ex),
                      r("online","Diploma + portfolio (part-time, study from home)",'online',2,1*L,.3*L,0,0,[])],
 "game":  lambda ex: [r("govt","B.Tech CSE, government college",'govt',4,.6*L,.72*L,1*L,3000,ex),
                      r("private","B.Sc Game Design, private college",'private',3,2.5*L,1.2*L,0,1000,[])],
 "media": lambda ex: [r("govt","BA Journalism / Mass Comm, government college",'govt',3,.15*L,.6*L,0,1000,ex),
                      r("private","BA Mass Communication, private college",'private',3,2*L,1*L,0,1000,ex)],
 "ca":    lambda ex: [r("distance","CA via ICAI (Foundation, Inter, Final + articleship)",'distance',5,.3*L,.5*L,1.5*L,10000,ex),
                      r("private","B.Com + CA with full-time coaching",'private',5,.8*L,.8*L,2*L,10000,ex)],
 "fin":   lambda ex: [r("govt","B.Com + MBA (Finance), government institutes",'govt',5,.6*L,.7*L,.3*L,3000,ex),
                      r("private","BBA + MBA (Finance), private institutes",'private',5,3*L,1.1*L,.3*L,3000,ex)],
 "bba":   lambda ex: [r("govt","BBA, government college",'govt',3,.3*L,.7*L,0,1000,ex),
                      r("ipm","Integrated programme in management (5 yr, IIM)",'govt',5,4*L,1*L,.5*L,4000,ex)],
 "llb":   lambda ex: [r("nlu","5-yr BA LLB at a National Law University",'govt',5,2.5*L,.9*L,.6*L,4000,ex),
                      r("govt","5-yr BA LLB at a government law college",'govt',5,.2*L,.6*L,.2*L,1000,[]),
                      r("private","5-yr BA LLB at a private university",'private',5,2*L,1*L,.3*L,2000,ex)],
 "upsc":  lambda ex: [r("govt","Any degree (govt college) + 2 yrs preparation",'govt',5,.15*L,.72*L,1.5*L,1000,ex),
                      r("private","Degree (private) + coaching institute",'private',5,1*L,1.2*L,2.5*L,1000,ex)],
 "bed":   lambda ex: [r("govt","Degree + B.Ed, government colleges",'govt',5,.15*L,.6*L,0,1000,ex),
                      r("private","Degree + B.Ed, private colleges",'private',5,.8*L,.8*L,0,1000,ex)],
 "agri":  lambda ex: [r("govt","B.Sc Agriculture at a state agricultural university",'govt',4,.5*L,.6*L,.2*L,1500,ex),
                      r("private","B.Sc Agriculture, private college",'private',4,1.5*L,.9*L,0,1500,ex)],
 "diploma":lambda ex:[r("govt","Diploma at a government polytechnic",'govt',3,.1*L,.48*L,0,500,ex),
                      r("iti","ITI trade certificate + apprenticeship",'govt',2,.05*L,.4*L,0,0,[])],
}
PCM, PCB, PCMB, COM, HUM = "sciencePcm","sciencePcb","sciencePcmb","commerce","humanities"
SCI_ENG=[PCM,PCMB]; SCI_MED=[PCB,PCMB]; ANY=[]
# id, name, cluster, emerging, streams, vector(15, 0-9), salary LPA (start, y5, y10), jobVelocity %, disruption, salaryGrowth %, route, exams, demand, summary
C = [
("software-engineer","Software engineer","engineeringTech",False,SCI_ENG,[4,7,3,3,4,6,7,8,5,5,5,6,7,6,5],(6,14,28),8,.45,9,"btech",["jee-main","viteee","tnea"],"tech","Designs, builds and maintains software products and systems."),
("ai-ml-engineer","AI / ML engineer","dataAi",True,SCI_ENG,[3,9,3,2,4,5,9,9,5,5,6,8,7,5,6],(8,20,40),32,.2,14,"btech",["jee-main","jee-advanced","viteee"],"tech","Builds machine-learning models and AI-powered products."),
("cybersecurity-analyst","Cybersecurity analyst","engineeringTech",True,SCI_ENG,[4,8,2,3,4,7,7,9,5,5,5,6,8,5,5],(6,15,30),22,.2,12,"btech",["jee-main","viteee"],"tech","Protects organisations from digital attacks and data breaches."),
("robotics-engineer","Robotics engineer","engineeringTech",True,SCI_ENG,[8,8,4,3,4,5,8,8,4,8,7,7,7,6,6],(5,12,25),20,.2,11,"btech",["jee-main","viteee","tnea"],"mfg","Designs robots and automation systems for factories, hospitals and farms."),
("ev-engineer","Electric vehicle engineer","engineeringTech",True,SCI_ENG,[8,8,3,3,4,5,8,7,4,7,6,7,7,6,6],(5,12,24),26,.2,12,"btech",["jee-main","viteee","tnea"],"mfg","Works on batteries, motors and power electronics for EVs."),
("mechanical-engineer","Mechanical engineer","engineeringTech",False,SCI_ENG,[8,7,3,3,4,6,7,7,4,8,5,5,7,6,4],(4,8,16),4,.4,6,"btech",["jee-main","tnea"],"mfg","Designs and improves machines, engines and manufacturing processes."),
("civil-engineer","Civil engineer","engineeringTech",False,SCI_ENG,[8,6,3,4,4,7,7,6,4,8,4,4,8,6,3],(3.5,7,14),6,.35,6,"btech",["jee-main","tnea"],"infra","Plans and builds roads, bridges, buildings and water systems."),
("vlsi-engineer","Electronics / VLSI chip engineer","engineeringTech",True,SCI_ENG,[6,9,2,2,3,6,9,8,4,7,5,6,8,5,4],(6,14,28),18,.25,11,"btech",["jee-main","jee-advanced","viteee"],"tech","Designs semiconductor chips and electronic systems."),
("renewable-energy-engineer","Renewable energy engineer","engineeringTech",True,SCI_ENG,[7,8,3,4,4,5,7,7,4,6,6,7,7,6,5],(4.5,10,20),24,.15,11,"btech",["jee-main","tnea"],"energy","Designs solar, wind and storage systems."),
("biomedical-engineer","Biomedical engineer","engineeringTech",True,[PCM,PCMB,PCB],[6,8,5,6,3,5,7,7,5,7,7,7,8,6,4],(4,9,18),15,.2,10,"btech",["jee-main","tnea","viteee"],"health","Designs medical devices, implants and health-tech used by doctors."),
("data-analyst","Data analyst","dataAi",True,ANY,[3,7,2,3,4,8,8,8,6,4,4,6,8,6,4],(5,10,20),20,.35,10,"analyst",["cuet-ug"],"tech","Turns business data into dashboards and decisions."),
("data-scientist","Data scientist","dataAi",True,ANY,[3,9,3,3,4,6,9,9,6,5,6,8,7,5,5],(7,16,32),25,.25,12,"bsc_ds",["cuet-ug"],"tech","Builds statistical and ML models to answer business questions."),
("product-manager","Product manager","dataAi",True,ANY,[3,6,4,6,8,5,6,7,8,4,6,8,7,8,7],(10,22,45),12,.2,12,"pm",["jee-main","cuet-ug"],"tech","Decides what a tech product should do and leads the team building it."),
("doctor-mbbs","Doctor (MBBS)","healthMedicine",False,SCI_MED,[5,9,2,8,3,5,6,7,6,5,4,6,9,7,3],(8,15,35),10,.1,9,"mbbs",["neet-ug"],"health","Diagnoses and treats patients; can specialise after MD/MS."),
("dentist","Dentist (BDS)","healthMedicine",False,SCI_MED,[7,8,4,6,4,5,5,6,5,7,4,5,9,6,4],(4,8,16),4,.1,6,"bds",["neet-ug"],"health","Diagnoses and treats teeth and oral health."),
("nurse","Nurse","healthMedicine",False,SCI_MED,[5,6,2,9,3,6,5,5,6,4,3,5,8,9,3],(3,5,9),14,.1,7,"nursing",["neet-ug"],"health","Provides patient care in hospitals; strong demand in India and abroad."),
("pharmacist","Pharmacist","healthMedicine",False,SCI_MED+[PCM],[4,7,2,5,4,8,6,6,5,4,3,5,8,6,3],(3,5,9),8,.3,6,"bpharm",["tnea"],"pharma","Prepares and dispenses medicines; works in hospitals and pharma."),
("physiotherapist","Physiotherapist","healthMedicine",False,SCI_MED,[7,6,3,8,4,5,5,5,6,6,4,6,8,8,4],(3,6,11),12,.1,8,"bpt",[],"health","Helps patients recover movement after injury or surgery."),
("clinical-psychologist","Clinical psychologist","healthMedicine",True,ANY,[2,8,5,9,3,4,5,7,8,3,6,8,7,8,4],(4,8,16),16,.1,9,"psych",["cuet-ug"],"health","Assesses and treats mental-health conditions."),
("biotechnologist","Biotechnologist","lifeSciences",True,SCI_MED+[PCM],[5,9,3,4,4,6,7,7,5,5,6,7,8,6,5],(4,8,16),14,.25,9,"btech",["jee-main","neet-ug","viteee"],"pharma","Uses living systems to build medicines, vaccines and materials."),
("climate-scientist","Climate / environmental scientist","lifeSciences",True,[PCM,PCB,PCMB],[5,9,3,5,3,5,8,8,6,6,6,8,7,6,4],(5,10,20),18,.15,9,"bsc",["cuet-ug"],"research","Studies climate data to guide policy, insurance and farming."),
("research-scientist","Research scientist (basic sciences)","lifeSciences",False,[PCM,PCB,PCMB],[4,9,4,3,2,6,8,9,7,6,7,9,8,5,4],(5,9,18),6,.15,7,"bsres",["iiser-iat","cuet-ug"],"research","Does fundamental research in physics, chemistry, biology or maths."),
("ux-designer","UX / UI designer","designArts",True,ANY,[3,6,8,6,5,4,4,6,6,7,9,9,6,7,5],(5,12,24),18,.3,11,"bdes",["uceed","nid-dat"],"tech","Designs how apps and websites look, feel and work for people."),
("product-designer","Industrial / product designer","designArts",True,ANY,[6,6,8,4,5,4,5,6,5,9,9,8,7,6,5],(5,11,22),14,.25,10,"bdes",["uceed","nid-dat"],"mfg","Designs physical products, from appliances to medical devices."),
("architect","Architect","designArts",False,SCI_ENG,[6,6,8,4,5,5,6,6,5,9,9,8,8,6,4],(3.5,8,18),7,.25,7,"barch",["nata","jee-main"],"infra","Designs buildings and spaces that are safe, useful and beautiful."),
("fashion-designer","Fashion designer","designArts",False,ANY,[4,4,9,5,7,3,3,4,5,7,9,9,6,6,6],(3,7,15),6,.3,7,"nift",["nift"],"textiles","Designs clothing and accessories; strong links to textile clusters."),
("animation-vfx-artist","Animation / VFX artist","mediaAnimation",True,ANY,[4,4,9,3,4,4,3,5,4,8,9,8,7,6,5],(3,7,14),12,.4,8,"anim",[],"media","Creates animation and visual effects for films, games and ads."),
("game-developer","Game developer","mediaAnimation",True,ANY,[4,7,8,3,4,5,7,8,4,7,9,8,6,6,6],(4.5,10,20),16,.3,10,"game",["jee-main"],"tech","Designs and programs video games."),
("journalist-content","Journalist / content creator","mediaAnimation",False,ANY,[2,5,8,7,7,3,3,5,9,3,8,9,5,6,7],(3,7,14),8,.45,7,"media",["cuet-ug"],"media","Researches and tells stories through text, video and podcasts."),
("chartered-accountant","Chartered accountant","businessFinance",False,ANY,[3,6,2,4,6,9,9,8,6,3,3,4,9,5,3],(8,16,30),8,.35,8,"ca",["ca-foundation"],"finance","Audits accounts, manages tax and advises businesses on finance."),
("financial-analyst","Financial analyst","businessFinance",False,ANY,[3,7,2,4,7,8,9,8,6,3,4,5,8,6,6],(6,14,28),12,.35,9,"fin",["cuet-ug","ipmat"],"finance","Analyses investments, markets and company performance."),
("entrepreneur","Startup founder / entrepreneur","businessFinance",True,ANY,[5,6,6,6,9,4,6,7,7,5,8,9,6,7,9],(3,10,30),10,.15,12,"bba",["ipmat","cuet-ug"],"tech","Builds a new business; high uncertainty, high upside."),
("digital-marketer","Digital marketer","businessFinance",True,ANY,[2,5,7,6,8,5,5,6,8,3,8,8,6,7,6],(3.5,8,16),14,.4,9,"bba",["cuet-ug"],"tech","Grows brands online through content, ads and analytics."),
("lawyer","Lawyer","lawGovernance",False,ANY,[2,7,4,7,8,6,4,8,9,3,5,7,8,6,5],(4,10,25),6,.3,9,"llb",["clat"],"finance","Advises and represents clients in legal matters."),
("civil-services","Civil services officer (IAS/IPS etc.)","lawGovernance",False,ANY,[4,7,3,8,7,7,6,7,8,4,5,7,9,7,3],(9,13,20),2,.05,5,"upsc",["upsc-cse"],"govt","Runs government administration; selected through UPSC exams."),
("teacher","Teacher / educator","educationSocial",False,ANY,[3,6,5,9,5,5,5,6,8,4,6,7,8,9,3],(3,5,8),6,.15,5,"bed",["cuet-ug"],"govt","Teaches and mentors students in schools or coaching."),
("agritech-specialist","Agritech specialist","agriEnvironment",True,[PCM,PCB,PCMB],[8,7,3,5,6,5,6,6,5,6,6,7,7,6,6],(4,9,18),20,.2,10,"agri",["cuet-ug"],"agri","Uses drones, sensors and data to raise farm yields."),
("food-technologist","Food technologist","agriEnvironment",False,[PCM,PCB,PCMB],[6,8,3,4,4,7,6,6,5,5,5,6,8,6,4],(3.5,7,13),10,.3,7,"btech",["tnea","cuet-ug"],"agri","Develops and tests safe, processed food products."),
("cnc-automation-technician","CNC / automation technician","manufacturingSkilled",False,ANY,[9,5,2,3,3,7,6,6,3,8,4,4,8,6,3],(2.5,5,9),12,.45,6,"diploma",[],"mfg","Programs and runs CNC machines and factory automation."),
("textile-technologist","Textile technologist","manufacturingSkilled",False,SCI_ENG,[7,6,5,4,5,6,6,6,4,6,6,6,7,6,4],(3.5,7,13),8,.35,6,"btech",["tnea"],"textiles","Develops fabrics and improves textile production."),
]
assert len(C)==40, len(C)
careers=[]
for (cid,name,cl,em,streams,vec,sal,jv,dis,sg,route,exams,dem,summ) in C:
    assert len(vec)==15, cid
    req={d:round(v/10,2) for d,v in zip(DIMS,vec)}
    imp={d:round(0.3+0.7*v/10,2) for d,v in zip(DIMS,vec)}
    careers.append(dict(id=cid,name=name,cluster=cl,emerging=em,eligibleStreams=streams,summary=summ,
        requirement=req,importance=imp,routes=ROUTES[route](exams),
        salary=dict(startingINR=int(sal[0]*L),year5INR=int(sal[1]*L),year10INR=int(sal[2]*L)),
        market=dict(jobVelocity=jv,disruptionIndex=dis,salaryGrowthPct=sg,
                    regionalDemand={rid:v for rid,v in zip(RID,DEMAND[dem])}),
        relatedExamIds=exams,illustrative=True))

EXAMS=[
 ("jee-main","JEE Main","National Testing Agency",["Jan","Apr"],"Class 12 with PCM","https://jeemain.nta.nic.in"),
 ("jee-advanced","JEE Advanced (IITs)","IITs (rotating)",["May","Jun"],"Top JEE Main qualifiers","https://jeeadv.ac.in"),
 ("neet-ug","NEET-UG","National Testing Agency",["May"],"Class 12 with PCB","https://neet.nta.nic.in"),
 ("cuet-ug","CUET-UG","National Testing Agency",["May","Jun"],"Class 12, any stream (subject-wise)","https://cuet.nta.nic.in"),
 ("clat","CLAT (National Law Universities)","Consortium of NLUs",["Dec"],"Class 12, any stream","https://consortiumofnlus.ac.in"),
 ("nata","NATA (Architecture)","Council of Architecture",["Apr","May","Jun"],"Class 12 with Maths","https://www.nata.in"),
 ("nid-dat","NID DAT (Design)","National Institute of Design",["Dec","Jan"],"Class 12, any stream","https://admissions.nid.edu"),
 ("uceed","UCEED (B.Des at IITs)","IIT Bombay",["Jan"],"Class 12, any stream","https://www.uceed.iitb.ac.in"),
 ("nift","NIFT entrance","National Institute of Fashion Technology",["Feb"],"Class 12, any stream","https://www.nift.ac.in"),
 ("ipmat","IPMAT (IIM integrated management)","IIM Indore / IIM Rohtak",["May"],"Class 12, any stream","https://www.iimidr.ac.in"),
 ("tnea","TNEA (Tamil Nadu engineering admissions, marks-based)","Govt of Tamil Nadu",["May","Jun"],"Class 12 with PCM, TN eligibility","https://www.tneaonline.org"),
 ("viteee","VITEEE","VIT",["Apr"],"Class 12 with PCM/PCB","https://viteee.vit.ac.in"),
 ("ca-foundation","CA Foundation","ICAI",["Jan","May","Sep"],"After Class 12","https://www.icai.org"),
 ("upsc-cse","UPSC Civil Services","UPSC",["May","Jun"],"Any graduate, age 21+","https://upsc.gov.in"),
 ("iiser-iat","IISER Aptitude Test","IISERs",["Jun"],"Class 12 with science","https://iiseradmission.in"),
]
exams=[dict(id=a,name=b,conductingBody=c,typicalMonths=d,eligibility=e,officialUrl=f) for a,b,c,d,e,f in EXAMS]

def sch(id,name,provider,amount,url,note,**rules): return dict(id=id,name=name,provider=provider,amountINR=amount,officialUrl=url,note=note,rules=rules)
TECH=["engineeringTech","manufacturingSkilled","dataAi"]
scholarships=[
 sch("central-sector","Central Sector Scheme of Scholarship (college students)","Ministry of Education via NSP",12000,"https://scholarships.gov.in","Top 20 percentile in Class 12 board.",maxIncomeINR=450000,minMarksBand="b75to90",levels=["class12","ug"]),
 sch("inspire-she","INSPIRE Scholarship (SHE)","Dept. of Science & Technology",80000,"https://online-inspire.gov.in","For natural/basic science degrees; top 1% in board.",minMarksBand="above90",levels=["class12","ug"],clusters=["lifeSciences"]),
 sch("pm-yasasvi","PM YASASVI post-matric scholarship","Ministry of Social Justice via NSP",15000,"https://scholarships.gov.in","For OBC / EBC / DNT students.",maxIncomeINR=250000,categories=["obc"]),
 sch("post-matric-sc-st","Post-matric scholarship for SC/ST students","Govt of India / State via NSP",20000,"https://scholarships.gov.in","Covers fees and maintenance.",maxIncomeINR=250000,categories=["sc","st"]),
 sch("aicte-pragati","AICTE Pragati (girls in technical education)","AICTE",50000,"https://www.aicte-india.org","For girls in AICTE-approved degree/diploma courses.",maxIncomeINR=800000,genders=["female"],clusters=TECH),
 sch("aicte-saksham","AICTE Saksham (students with disability)","AICTE",50000,"https://www.aicte-india.org","Disability of 40% or more.",maxIncomeINR=800000,requiresDisability=True,clusters=TECH),
 sch("tn-pudhumai-penn","Pudhumai Penn (Tamil Nadu)","Govt of Tamil Nadu",12000,"https://www.pudhumaipenn.tn.gov.in","Girls who studied Class 6–12 in TN government schools.",states=["Tamil Nadu"],genders=["female"]),
 sch("tn-tamizh-pudhalvan","Tamizh Pudhalvan (Tamil Nadu)","Govt of Tamil Nadu",12000,"https://www.tn.gov.in","Boys who studied Class 6–12 in TN government schools.",states=["Tamil Nadu"],genders=["male"]),
 sch("tn-first-graduate","First Graduate tuition concession (Tamil Nadu)","Govt of Tamil Nadu",25000,"https://www.tneaonline.org","First graduate in the family, via TNEA counselling.",states=["Tamil Nadu"],requiresFirstGen=True,clusters=TECH),
 sch("kotak-kanya","Kotak Kanya Scholarship","Kotak Education Foundation",150000,"https://kotakeducationfoundation.org","Girls in professional degrees.",maxIncomeINR=600000,genders=["female"],minMarksBand="b75to90",clusters=["engineeringTech","healthMedicine","designArts","lawGovernance","dataAi"]),
 sch("reliance-ug","Reliance Foundation Undergraduate Scholarship","Reliance Foundation",50000,"https://www.scholarships.reliancefoundation.org","Merit-cum-means, any UG stream.",maxIncomeINR=1500000,levels=["class12","ug"]),
]

def idea(title,problem,strengths): return dict(title=title,problem=problem,strengths=strengths)
LOCAL=[
 ("Chennai","Tamil Nadu",[
   ("Automotive & EV manufacturing (Sriperumbudur–Oragadam belt)","One of India's largest auto clusters.",["ev-engineer","mechanical-engineer","robotics-engineer"],
     [idea("Battery health monitor for e-autos","Auto drivers can't see when their battery is degrading.",["numerical","logical","realistic"]),
      idea("Low-cost line-follower robot for small workshops","Small suppliers move parts by hand.",["realistic","spatial","creative"])]),
   ("Film, VFX & media (Kollywood)","Large film and VFX studio presence.",["animation-vfx-artist","journalist-content","game-developer"],
     [idea("Tamil folk-tale animated shorts for schools","Few local-language learning videos exist.",["artistic","creative","verbal"])]),
   ("Healthcare & medical tourism","Major hospital hub.",["doctor-mbbs","biomedical-engineer","nurse"],
     [idea("Medicine-reminder pill box for elders","Elderly patients miss doses.",["realistic","social","creative"])]),
 ]),
 ("Coimbatore","Tamil Nadu",[
   ("Pumps, motors & foundries","Known as the pump city of India.",["mechanical-engineer","cnc-automation-technician","robotics-engineer"],
     [idea("Solar-powered smart pump controller","Farm pumps waste power and water.",["realistic","numerical","logical"]),
      idea("3D-printed jigs for local foundries","Small foundries make jigs slowly by hand.",["spatial","creative","realistic"])]),
   ("Agriculture research (TNAU)","Home to the state agricultural university.",["agritech-specialist","food-technologist"],
     [idea("Coconut-tree disease photo checker","Farmers spot leaf disease too late.",["investigative","logical","social"])]),
 ]),
 ("Tiruppur","Tamil Nadu",[
   ("Knitwear export cluster","India's knitwear capital.",["textile-technologist","fashion-designer","data-analyst"],
     [idea("Fabric-waste upcycling marketplace","Tons of cutting waste are burnt or dumped.",["enterprising","creative","social"]),
      idea("Water-recycling monitor for dyeing units","Dye effluent pollutes the Noyyal river.",["investigative","numerical","realistic"])]),
 ]),
 ("Madurai","Tamil Nadu",[
   ("Temple tourism & handicrafts","Major pilgrimage and heritage city.",["product-designer","digital-marketer","entrepreneur"],
     [idea("3D heritage walk app for Meenakshi temple streets","Visitors miss the history around them.",["artistic","spatial","verbal"]),
      idea("Online store for Sungudi saree weavers","Weavers depend on middlemen.",["enterprising","creative","social"])]),
   ("Healthcare (eye care & hospitals)","Known for large-scale eye-care models.",["doctor-mbbs","biomedical-engineer","nurse"],
     [idea("Phone-based vision screening kiosk for rural schools","Many children never get eye tests.",["investigative","social","creative"])]),
   ("Agriculture & jasmine trade","Madurai malli (jasmine) is GI-tagged.",["agritech-specialist","food-technologist"],
     [idea("Cool-box to keep jasmine fresh longer","Flowers wilt before reaching markets.",["realistic","investigative","creative"])]),
 ]),
 ("Thanjavur","Tamil Nadu",[
   ("Cauvery delta agriculture","The rice bowl of Tamil Nadu.",["agritech-specialist","climate-scientist","food-technologist"],
     [idea("Flood alert SMS for paddy farmers","Sudden floods damage standing crops.",["investigative","social","logical"]),
      idea("Paddy-straw packaging material","Farmers burn straw after harvest.",["creative","realistic","enterprising"])]),
 ]),
 ("Thoothukkudi","Tamil Nadu",[
   ("Port, fisheries & salt pans","Major port and coastal fisheries.",["renewable-energy-engineer","climate-scientist","food-technologist"],
     [idea("Solar fish dryer for fisherwomen","Open-air drying spoils fish in rain.",["realistic","creative","social"]),
      idea("Boat GPS safety beacon","Fishers stray across maritime borders.",["realistic","logical","numerical"])]),
 ]),
 ("Krishnagiri","Tamil Nadu",[
   ("EV & two-wheeler manufacturing (Hosur)","Large EV and two-wheeler plants.",["ev-engineer","robotics-engineer","cnc-automation-technician"],
     [idea("Battery-swap station locator for e-scooters","Riders worry about running out of charge.",["logical","numerical","enterprising"])]),
   ("Mango farming","Known for mango orchards.",["agritech-specialist","food-technologist"],
     [idea("Mango ripeness sensor","Fruit is picked at the wrong time.",["investigative","realistic","numerical"])]),
 ]),
 ("Kancheepuram","Tamil Nadu",[
   ("Electronics manufacturing (Sriperumbudur)","Phone and electronics assembly plants.",["vlsi-engineer","robotics-engineer","cnc-automation-technician"],
     [idea("E-waste collection tracker for schools","Old phones end up in landfills.",["social","enterprising","logical"])]),
   ("Silk weaving","GI-tagged Kanchipuram silk.",["fashion-designer","textile-technologist","digital-marketer"],
     [idea("Silk authenticity checker app","Buyers can't tell real silk from fake.",["investigative","creative","verbal"])]),
 ]),
]
local=[]
for district,state,clusters in LOCAL:
    local.append(dict(district=district,state=state,clusters=[dict(name=n,description=d,relatedCareerIds=cids,ideas=ideas) for n,d,cids,ideas in clusters]))
local.append(dict(district="*",state="*",clusters=[
  dict(name="Local schools & community",description="Every district has schools, clinics and small businesses.",relatedCareerIds=["teacher","entrepreneur","data-analyst"],
       ideas=[idea("Bus-arrival alert for your school","Students wait long at bus stops.",["logical","numerical","social"]),
              idea("Waste-segregation game for kids","Households mix wet and dry waste.",["creative","artistic","social"])]),
  dict(name="Agriculture & food",description="Most districts have farms and food processing.",relatedCareerIds=["agritech-specialist","food-technologist"],
       ideas=[idea("Soil-moisture sensor with SMS alerts","Farmers over-water crops.",["realistic","investigative","numerical"])]),
]))

exam_ids=[x["id"] for x in exams]
for c in careers:
    for e in c["relatedExamIds"]: assert e in exam_ids, e
    for rr in c["routes"]:
        for e in rr["entryExamIds"]: assert e in exam_ids, e
ids={c["id"] for c in careers}
for l in local:
    for cl in l["clusters"]:
        for cid in cl["relatedCareerIds"]: assert cid in ids, cid
        for i in cl["ideas"]:
            for s in i["strengths"]: assert s in DIMS, s

def dump(name,obj):
    with open(os.path.join(OUT,name),"w",encoding="utf-8") as f: json.dump(obj,f,ensure_ascii=False,indent=1)
dump("careers.json",careers); dump("exams.json",exams); dump("scholarships.json",scholarships)
dump("regions.json",[dict(id=a,name=b,state=c,lat=d,lng=e,isMetro=f,isAbroad=g) for a,b,c,d,e,f,g in REGIONS])
dump("local_industries.json",local)
print("careers",len(careers),"exams",len(exams),"scholarships",len(scholarships),"districts",len(local))
