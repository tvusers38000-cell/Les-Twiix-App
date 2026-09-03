import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<int> claimLivePresenceReward() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null || user.isAnonymous) {
    return 0;
  }

  final firestore = FirebaseFirestore.instance;

  try {
    final challengeSnapshot = await firestore
        .collection('challenges')
        .where('type', isEqualTo: 'live_presence')
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? activeChallenge;

    final now = DateTime.now();

    for (final doc in challengeSnapshot.docs) {
      final data = doc.data();

      if (data['active'] != true) {
        continue;
      }

      final endAtRaw = data['endAt'];
      final endAt =
          endAtRaw is Timestamp ? endAtRaw.toDate() : null;

      if (endAt != null && !endAt.isAfter(now)) {
        continue;
      }

      activeChallenge = doc;
      break;
    }

    if (activeChallenge == null) {
      return 0;
    }

    final challengeData = activeChallenge.data();

    final points =
        (challengeData['points'] as num?)?.toInt() ?? 0;

    if (points <= 0) {
      return 0;
    }

    final challengeId = activeChallenge.id;

    final userRef =
        firestore.collection('users').doc(user.uid);

    final rewardRef = userRef
        .collection('challengeRewards')
        .doc(challengeId);

    return await firestore.runTransaction<int>(
      (transaction) async {
        final rewardSnapshot =
            await transaction.get(rewardRef);

        final userSnapshot =
            await transaction.get(userRef);

        if (rewardSnapshot.exists ||
            !userSnapshot.exists) {
          return 0;
        }

        final userData = userSnapshot.data();

        final currentPoints =
            (userData?['twiixPoints'] as num?)
                    ?.toInt() ??
                0;

        transaction.set(rewardRef, {
          'challengeId': challengeId,
          'type': 'live_presence',
          'points': points,
          'awardedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          'twiixPoints': currentPoints + points,
          'lastChallengeRewardId': challengeId,
        });

        return points;
      },
    );
  } catch (_) {
    return 0;
  }
}
