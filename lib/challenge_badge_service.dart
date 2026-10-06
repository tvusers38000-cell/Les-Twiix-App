import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List<String>> syncChallengeBadges() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null || user.isAnonymous) {
    return <String>[];
  }

  final firestore = FirebaseFirestore.instance;
  final userRef = firestore.collection('users').doc(user.uid);

  final rewardsSnapshot =
      await userRef.collection('challengeRewards').get();

  final challengeCount = rewardsSnapshot.docs.length;

  final thresholds = <String, int>{
    'first_challenge': 1,
    'challenges_10': 10,
    'challenges_50': 50,
    'challenges_100': 100,
  };

  final unlockedNow = <String>[];

  for (final entry in thresholds.entries) {
    if (challengeCount < entry.value) {
      continue;
    }

    final badgeRef =
        userRef.collection('badges').doc(entry.key);

    final badgeSnapshot = await badgeRef.get();

    if (badgeSnapshot.exists) {
      continue;
    }

    await badgeRef.set({
      'badgeId': entry.key,
      'unlockedAt': FieldValue.serverTimestamp(),
    });

    unlockedNow.add(entry.key);
  }

  await userRef.set({
    'completedChallenges': challengeCount,
  }, SetOptions(merge: true));

  return unlockedNow;
}
