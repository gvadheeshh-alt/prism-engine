import json, math
D=json.load(open("assets/data/careers.json")); CAR={c["id"]:c for c in D}
SCH=json.load(open("assets/data/scholarships.json")); REG=json.load(open("assets/data/regions.json"))
P=json.load(open("assets/data/personas.json"))
DIMS=list(D[0]["requirement"].keys())
MB=["below50","b50to60","b60to75","b75to90","above90"]; MOB=["local","state","india","abroad"]
def ccos(a,b,w):
    sw=sum(w.values()); ma=sum(w[d]*a[d] for d in DIMS)/sw; mb=sum(w[d]*b[d] for d in DIMS)/sw
    n=sum(w[d]*(a[d]-ma)*(b[d]-mb) for d in DIMS); x=math.sqrt(sum(w[d]*(a[d]-ma)**2 for d in DIMS)); y=math.sqrt(sum(w[d]*(b[d]-mb)**2 for d in DIMS))
    return 0.0 if x==0 or y==0 else n/(x*y)
RIASEC_DIMS=["realistic","investigative","artistic","social","enterprising","conventional"]
def fit(S,c):
    """Interests decide the shape match (RIASEC only); aptitude and work style decide readiness (shortfall)."""
    R,W=c["requirement"],c["importance"]
    sw=sum(W[d] for d in RIASEC_DIMS); ma=sum(W[d]*S[d] for d in RIASEC_DIMS)/sw; mb=sum(W[d]*R[d] for d in RIASEC_DIMS)/sw
    cov=sum(W[d]*(S[d]-ma)*(R[d]-mb) for d in RIASEC_DIMS); va=sum(W[d]*(S[d]-ma)**2 for d in RIASEC_DIMS); vb=sum(W[d]*(R[d]-mb)**2 for d in RIASEC_DIMS)
    r=0 if va<1e-12 or vb<1e-12 else cov/math.sqrt(va*vb)
    other=[d for d in DIMS if d not in RIASEC_DIMS]
    sf=sum(W[d]*max(0,R[d]-S[d]) for d in other)/sum(W[d] for d in other)
    return .65*max(0,r)+.35*(1-sf)
def sal(c,t):
    s=c["salary"]; a,b,z=s["startingINR"],s["year5INR"],s["year10INR"]
    return a+(b-a)*(t-1)/4 if t<=5 else b+(z-b)*(t-5)/5
def schol(st,pa,c):
    out=[]
    for s in SCH:
        r=s["rules"]; ctx=st["context"]
        if "maxIncomeINR" in r and pa["annualIncomeINR"]>r["maxIncomeINR"]: continue
        if "states" in r and ctx["state"] not in r["states"]: continue
        g=pa.get("childGender") or ctx.get("gender")
        if "genders" in r and g not in r["genders"]: continue
        cat=pa.get("category") or ctx.get("category")
        if "categories" in r and cat not in r["categories"]: continue
        if "minMarksBand" in r and MB.index(ctx["marksBand"])<MB.index(r["minMarksBand"]): continue
        if "levels" in r and ctx["level"] not in r["levels"] and ctx["level"] not in ["class9","class10","class11"]: continue
        if r.get("requiresFirstGen") and not pa.get("firstGenerationLearner"): continue
        if r.get("requiresDisability"): continue
        if "clusters" in r and c["cluster"] not in r["clusters"]: continue
        out.append(s)
    return out
LIM={"none":0,"moderate":750000,"high":2000000}
def route_fin(st,pa,c,rt):
    y=rt["years"]; TC=(rt["tuitionPerYearINR"]+rt["livingPerYearINR"])*y+rt["coachingINR"]+rt["examFeesINR"]
    ss=sorted([s["amountINR"] for s in schol(st,pa,c)],reverse=True)[:2]
    sch=0.5*min(sum(ss)*y, rt["tuitionPerYearINR"]*y)
    emi=0.35*c["salary"]["startingINR"]/12
    if pa["maxMonthlyEmiINR"]>0: emi=min(emi,pa["maxMonthlyEmiINR"])
    i=.09/12; pvl=emi*(1-(1+i)**-84)/i
    loan=0 if pa["loanComfort"]=="none" else min(LIM[pa["loanComfort"]],pvl)
    FC=pa["savingsForEducationINR"]+sch+loan; F=min(1,FC/TC) if TC>0 else 1
    npvc=sum(sal(c,t)/1.08**(y+t) for t in range(1,11)); npvb=sum(180000*1.05**(k-1)/1.08**k for k in range(1,y+11))
    roi=(npvc-npvb-TC)/TC
    return dict(id=rt["id"],TC=TC,F=F,roi=roi,sch=sch,loan=loan)
def finance(st,pa,c):
    rs=[route_fin(st,pa,c,r) for r in c["routes"]]
    v=sorted([r for r in rs if r["F"]>=.6],key=lambda r:r["TC"])
    tiers={rt["id"]:rt["tier"] for rt in c["routes"]}
    flex=[r for r in v if tiers[r["id"]] in ("online","distance")]
    if st["context"]["level"] in ("ug","pg") and flex: best=flex[0]
    else: best=v[0] if v else max(rs,key=lambda r:r["F"])
    return best
JV=[c["market"]["jobVelocity"] for c in D]; SG=[c["market"]["salaryGrowthPct"] for c in D]
def mm(v,a): return (v-min(a))/(max(a)-min(a))
def geo(st,c):
    ctx=st["context"]; dem=c["market"]["regionalDemand"]; mob=ctx["mobility"]
    def inr(r):
        if mob=="abroad": return True
        if r["isAbroad"]: return False
        if mob=="india": return True
        if mob=="state": return r["state"]==ctx["state"]
        return r["name"].lower()==ctx["district"].lower()
    v=[dem[r["id"]] for r in REG if inr(r)]
    if v: return max(v)
    v=[dem[r["id"]] for r in REG if r["state"]==ctx["state"]]
    return 0.8*max(v) if v else 0.5
def vrank(v): return sum(1 for x in JV if x<v)/(len(JV)-1)
def market(st,c):
    m=c["market"]; return .35*vrank(m["jobVelocity"])+.25*(1-m["disruptionIndex"])+.2*mm(m["salaryGrowthPct"],SG)+.2*geo(st,c)
def csim(a,b):
    if a["id"]==b["id"]: return 1.0
    return .3*(a["cluster"]==b["cluster"])+.7*max(0,ccos(a["requirement"],b["requirement"],{d:1 for d in DIMS}))
def palign(pa,c):
    p=pa["preferredCareerIds"]
    return max(csim(c,CAR[x]) for x in p) if p else .5
def conflict(st,pa):
    sd=st["context"]["dreamCareerIds"]; pp=pa["preferredCareerIds"]
    if sd and pp:
        o1=sum(max(csim(CAR[a],CAR[b]) for b in pp) for a in sd)/len(sd)
        o2=sum(max(csim(CAR[b],CAR[a]) for a in sd) for b in pp)/len(pp)
        pref=1-(o1+o2)/2
    else: pref=.5
    risk=abs(st["dims"]["riskTolerance"]-pa["riskAppetite"])
    def at25(c): s=c["salary"]; return s["startingINR"]+(s["year5INR"]-s["startingINR"])*.4
    proj=sum(at25(CAR[x]) for x in sd)/len(sd) if sd else 0
    e=pa["expectedSalaryAt25INR"]; sg=max(0,(e-proj)/e) if e>0 and sd else 0
    rel=abs(MOB.index(st["context"]["mobility"])-MOB.index(pa["relocationAcceptance"]))/3
    ys={"class9":4,"class10":3,"class11":2,"class12":1,"ug":0,"pg":0}[st["context"]["level"]]
    yrs=ys+(sum(min(r["years"] for r in CAR[x]["routes"]) for x in sd)/len(sd) if sd else 4)
    tl=min(1,max(0,(yrs-pa["preferredYearsToEarning"])/4))
    rt=(rel+tl)/2
    psci=100*(.35*pref+.25*risk+.2*sg+.2*rt)
    return psci,dict(pref=pref,risk=risk,sal=sg,rt=rt)
def run(p):
    st,pa=p["student"],p["parent"]; S=st["dims"]; psci,comp=conflict(st,pa)
    rows=[]
    for c in D:
        f=fit(S,c); fin=finance(st,pa,c); F=fin["F"]
        ctx=st["context"]
        if ctx["level"] in ["class11","class12","ug","pg"] and c["eligibleStreams"] and ctx["stream"]!="undecided" and ctx["stream"] not in c["eligibleStreams"]: F*=.3
        M=market(st,c); roi=min(fin["roi"],6); rn=max(0,(roi+1)/(roi+4)) if roi>-1 else 0
        pen=10*psci/100*(1-palign(pa,c))
        score=100*(.45*f+.2*M+.15*F+.2*rn)-pen
        rows.append((score,c["id"],f,M,F,rn,pen,fin["id"],fin["roi"]))
    rows.sort(reverse=True)
    print("==",p["id"],"PSCI %.1f"%psci,{k:round(v,2) for k,v in comp.items()})
    for r in rows[:8]: print("  %5.1f %-26s fit %.2f mkt %.2f F %.2f roiN %.2f pen %.1f route %s roi %.1f"%r)
    fits=sorted(((fit(S,c),c["id"]) for c in D),reverse=True)
    if p["id"]=="priya":
        for x in ["architect","ux-designer","product-designer","biomedical-engineer","doctor-mbbs","ai-ml-engineer"]: print("   fit",x,round(fit(S,CAR[x]),2))
    print("  fit range %.2f..%.2f"%(fits[-1][0],fits[0][0]))
    bridges=sorted(((2*fit(S,c)*palign(pa,c)/(fit(S,c)+palign(pa,c)),c["id"],round(fit(S,c),2),round(palign(pa,c),2)) for c in D if c["id"] not in pa["preferredCareerIds"]+st["context"]["dreamCareerIds"] and not (st["context"]["level"] in ["class11","class12","ug","pg"] and c["eligibleStreams"] and st["context"]["stream"]!="undecided" and st["context"]["stream"] not in c["eligibleStreams"])),reverse=True)[:4]
    print("  bridges",bridges)
for p in P: run(p)
