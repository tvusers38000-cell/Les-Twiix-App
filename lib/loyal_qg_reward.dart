import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<int> recordQGVisit() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null || user.isAnonymous) {
    return 0;
  }

  final firestore = FirebaseFirestore.instance;

  try {
    final userRef =
        firestore.collection('users').doc(user.uid);

    final visitsRef =
        userRef.collection('progress').doc('visits');

    final supporterBadgeRef =
        userRef.collection('badges').doc('twiix_supporter');

    QueryDocumentSnapshot<Map<String, dynamic>>?
        activeChallenge;

    final challengeSnapshot = await firestore
        .collection('challenges')
        .where('type', isEqualTo: 'loyal_qg_5_days')
        .get();

    final now = DateTime.now();

    for (final doc in challengeSnapshot.docs) {
      final data = doc.data();

      if (data['active'] != true) continue;

      final endAtRaw = data['endAt'];
      final endAt =
          endAtRaw is Timestamp ? endAtRaw.toDate() : null;

      if (endAt != null && !endAt.isAfter(now)) {
        continue;
      }

      activeChallenge = doc;
      break;
    }

    final challengeId = activeChallenge?.id;
    final challengeData = activeChallenge?.data();

    final points =
        (challengeData?['points'] as num?)?.toInt() ?? 0;

    final rewardRef = challengeId == null
        ? null
        : userRef
            .collection('challengeRewards')
            .doc(challengeId);

    return await firestore.runTransaction<int>(
      (transaction) async {
        // Toutes les lectures Firestore sont faites
        // AVANT la première écriture.
        final visitsSnapshot =
            await transaction.get(visitsRef);

        final userSnapshot =
            await transaction.get(userRef);

        final supporterBadgeSnapshot =
            await transaction.get(supporterBadgeRef);

        DocumentSnapshot<Map<String, dynamic>>?
            rewardSnapshot;

        if (rewardRef != null) {
          rewardSnapshot =
              await transaction.get(rewardRef);
        }

        if (!userSnapshot.exists) {
          return 0;
        }

        final visitsData = visitsSnapshot.data();

        final currentCount =
            (visitsData?['count'] as num?)?.toInt() ?? 0;

        final lastVisitRaw = visitsData?['lastVisitAt'];
        final lastVisit = lastVisitRaw is Timestamp
            ? lastVisitRaw.toDate()
            : null;

        var nextCount = currentCount;

        final isNewVisit = lastVisit == null ||
            DateTime.now().difference(lastVisit) >=
                const Duration(hours: 20);

        if (isNewVisit) {
          nextCount = currentCount + 1;

          transaction.set(
            visitsRef,
            {
              'count': nextCount,
              'lastVisitAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        if (nextCount >= 5 &&
            !supporterBadgeSnapshot.exists) {
          transaction.set(supporterBadgeRef, {
            'badgeId': 'twiix_supporter',
            'unlockedAt': FieldValue.serverTimestamp(),
          });
        }

        if (rewardRef == null ||
            rewardSnapshot?.exists == true ||
            nextCount < 5 ||
            points <= 0) {
          return 0;
        }

        final userData = userSnapshot.data();

        final currentPoints =
            (userData?['twiixPoints'] as num?)
                    ?.toInt() ??
                0;

        transaction.set(rewardRef, {
          'challengeId': challengeId,
          'type': 'loyal_qg_5_days',
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
