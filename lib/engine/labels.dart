import '../models/models.dart';

String clusterLabel(CareerCluster c) => switch (c) {
      CareerCluster.engineeringTech => 'Engineering & technology',
      CareerCluster.dataAi => 'Data & AI',
      CareerCluster.healthMedicine => 'Health & medicine',
      CareerCluster.lifeSciences => 'Life & earth sciences',
      CareerCluster.designArts => 'Design & architecture',
      CareerCluster.mediaAnimation => 'Media & animation',
      CareerCluster.businessFinance => 'Business & finance',
      CareerCluster.lawGovernance => 'Law & governance',
      CareerCluster.educationSocial => 'Education & social',
      CareerCluster.agriEnvironment => 'Agriculture & food',
      CareerCluster.manufacturingSkilled => 'Manufacturing & skilled trades',
    };

String streamLabel(AcademicStream s) => switch (s) {
      AcademicStream.sciencePcm => 'Science (PCM)',
      AcademicStream.sciencePcb => 'Science (PCB)',
      AcademicStream.sciencePcmb => 'Science (PCMB)',
      AcademicStream.commerce => 'Commerce',
      AcademicStream.humanities => 'Humanities',
      AcademicStream.vocational => 'Vocational',
      AcademicStream.undecided => 'Not decided yet',
    };

String levelLabel(StudyLevel l) => switch (l) {
      StudyLevel.class9 => 'Class 9',
      StudyLevel.class10 => 'Class 10',
      StudyLevel.class11 => 'Class 11',
      StudyLevel.class12 => 'Class 12',
      StudyLevel.ug => 'Undergraduate',
      StudyLevel.pg => 'Postgraduate',
    };

String marksLabel(MarksBand m) => switch (m) {
      MarksBand.below50 => 'Below 50%',
      MarksBand.b50to60 => '50–60%',
      MarksBand.b60to75 => '60–75%',
      MarksBand.b75to90 => '75–90%',
      MarksBand.above90 => 'Above 90%',
    };

String mobilityLabel(Mobility m) => switch (m) {
      Mobility.local => 'Stay in my city',
      Mobility.state => 'Anywhere in my state',
      Mobility.india => 'Anywhere in India',
      Mobility.abroad => 'Open to going abroad',
    };

String loanLabel(LoanComfort l) => switch (l) {
      LoanComfort.none => 'No loan',
      LoanComfort.moderate => 'A moderate loan is okay',
      LoanComfort.high => 'A large loan is okay',
    };

String tierLabel(RouteTier t) => switch (t) {
      RouteTier.govt => 'Government',
      RouteTier.private => 'Private',
      RouteTier.distance => 'Self-study / distance',
      RouteTier.online => 'Online',
      RouteTier.lateralEntry => 'Diploma + lateral entry',
    };

String bandLabel(ConflictBand b) => switch (b) {
      ConflictBand.aligned => 'Aligned',
      ConflictBand.mild => 'Mild disagreement',
      ConflictBand.significant => 'Significant disagreement',
      ConflictBand.high => 'High disagreement',
    };
