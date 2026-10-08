import 'dart:math' as math;

import '../models/models.dart';

class HyperLocalResult {
  final List<InnovationIdea> ideas;
  final String area;
  const HyperLocalResult(this.ideas, this.area);
}

class _Candidate {
  final InnovationIdea idea;
  final String cluster;
  final double score;
  const _Candidate(this.idea, this.cluster, this.score);
}

/// Stage 3, step 9: Hyper-local STEAM innovation ideas.
/// Score per idea = 0.7 × mean(student strength on the idea's dims) + 0.3 × best fit among the
/// careers that local cluster feeds (+0.1 if it is from the student's own district).
/// Picks 3, preferring different industry clusters.
HyperLocalResult hyperLocalIdeas(StudentVector s, List<LocalIndustry> all, Map<String, double> fitByCareer) {
  final district = s.context.district.trim().toLowerCase();
  LocalIndustry? local;
  for (final l in all) {
    if (l.district.toLowerCase() == district) local = l;
  }
  final generic = all.where((l) => l.district == '*');
  final sources = [if (local != null) local, ...generic];
  final area = local?.district ?? (s.context.district.isEmpty ? 'your area' : s.context.district);

  final candidates = <_Candidate>[];
  for (final src in sources) {
    final bonus = src.district == '*' ? 0.0 : 0.1;
    for (final cl in src.clusters) {
      final bestFit = cl.relatedCareerIds
          .map<double>((id) => fitByCareer[id] ?? 0.0)
          .fold<double>(0.0, (a, b) => a > b ? a : b);
      for (final t in cl.ideas) {
        final strength = t.strengths.isEmpty
            ? 0.5
            : t.strengths.map((d) => s.dims[d]).reduce((a, b) => a + b) / t.strengths.length;
        final match = 0.7 * strength + 0.3 * bestFit;
        candidates.add(_Candidate(
          InnovationIdea(
            title: t.title,
            localIndustry: cl.name,
            problem: t.problem,
            strengthsUsed: t.strengths,
            careerIds: cl.relatedCareerIds,
            matchScore: math.min(1.0, match),
          ),
          cl.name,
          match + bonus,
        ));
      }
    }
  }

  final picked = <InnovationIdea>[];
  final usedClusters = <String>{};
  while (picked.length < 3 && candidates.isNotEmpty) {
    double adjusted(_Candidate c) => c.score - (usedClusters.contains(c.cluster) ? 0.15 : 0);
    candidates.sort((a, b) => adjusted(b).compareTo(adjusted(a)));
    final next = candidates.removeAt(0);
    picked.add(next.idea);
    usedClusters.add(next.cluster);
  }
  return HyperLocalResult(picked, area);
}
