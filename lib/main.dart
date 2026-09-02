import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pink = Color(0xFFFF2C7D);
const blue = Color(0xFF3C7CFF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  final state = await TwiixState.load();
  runApp(TwiixApp(state: state));
}

class TwiixApp extends StatelessWidget {
  final TwiixState state;
  const TwiixApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Les Twiix',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07070B),
        colorScheme: const ColorScheme.dark(primary: pink, secondary: blue, surface: Color(0xFF111117)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111117),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      home: TwiixIntro(state: state),
    );
  }
}

class NewsItem {
  String title;
  String body;
  NewsItem(this.title, this.body);
  Map<String, dynamic> toJson() => {'title': title, 'body': body};
  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(j['title'] ?? '', j['content'] ?? j['body'] ?? '');
}

class LiveItem {
  String day;
  String time;
  String title;
  bool active;
  DateTime? scheduledAt;
  LiveItem(this.day, this.time, this.title, {this.active = true, this.scheduledAt});
  Map<String, dynamic> toJson() => {
    'day': day,
    'time': time,
    'title': title,
    'active': active,
    'scheduledAt': scheduledAt?.toIso8601String(),
  };
  factory LiveItem.fromJson(Map<String, dynamic> j) => LiveItem(
    j['day'] ?? '',
    j['time'] ?? '',
    j['title'] ?? '',
    active: j['active'] ?? true,
    scheduledAt: j['scheduledAt'] != null ? DateTime.tryParse(j['scheduledAt']) : null,
  );
}

class Donor {
  String name;
  int points;
  Donor(this.name, this.points);
  Map<String, dynamic> toJson() => {'name': name, 'points': points};
  factory Donor.fromJson(Map<String, dynamic> j) => Donor(j['name'] ?? '', j['points'] ?? 0);
}

class Challenge {
  String title;
  String subtitle;
  int points;
  Challenge(this.title, this.subtitle, this.points);
  Map<String, dynamic> toJson() => {'title': title, 'subtitle': subtitle, 'points': points};
  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(j['title'] ?? '', j['subtitle'] ?? '', j['points'] ?? 0);
}

class PollItem {
  String id;
  String question;
  List<String> options;
  List<int> votes;
  DateTime endAt;

  PollItem({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.endAt,
  });

  bool get isFinished => DateTime.now().isAfter(endAt);

  int get totalVotes => votes.fold(0, (total, value) => total + value);
}


class TwiixState extends ChangeNotifier {
  final SharedPreferences prefs;
  bool isLive;
  List<NewsItem> news;
  List<LiveItem> lives;
  List<Donor> donors;
  List<Challenge> challenges;
  List<PollItem> polls;

  TwiixState(this.prefs, {required this.isLive, required this.news, required this.lives, required this.donors, required this.challenges, required this.polls});

  static Future<TwiixState> load() async {
    final p = await SharedPreferences.getInstance();
    List<T> decodeList<T>(String key, T Function(Map<String, dynamic>) build, List<T> fallback) {
      final raw = p.getString(key);
      if (raw == null) return fallback;
      try {
        return (jsonDecode(raw) as List).map((e) => build(Map<String, dynamic>.from(e))).toList();
      } catch (_) {
        return fallback;
      }
    }
    List<NewsItem>? firestoreNews;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('news')
          .get();
      firestoreNews = snap.docs
          .map((doc) => NewsItem.fromJson(doc.data()))
          .toList();
    } catch (_) {}

    List<LiveItem>? firestoreLives;
    try {
      final snap = await FirebaseFirestore.instance.collection('lives').get();
      final now = DateTime.now();
      firestoreLives = snap.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['scheduledAt'];
        final scheduledAt = timestamp is Timestamp ? timestamp.toDate() : null;
        return LiveItem(
          data['day'] ?? '',
          data['time'] ?? '',
          data['title'] ?? '',
          active: data['active'] ?? true,
          scheduledAt: scheduledAt,
        );
      }).where((live) => live.scheduledAt == null || live.scheduledAt!.isAfter(now)).toList();
      firestoreLives.sort((a, b) {
        if (a.scheduledAt == null) return 1;
        if (b.scheduledAt == null) return -1;
        return a.scheduledAt!.compareTo(b.scheduledAt!);
      });
    } catch (_) {}

    List<PollItem> firestorePolls = [];
    try {
      final snap = await FirebaseFirestore.instance.collection('polls').get();
      firestorePolls = snap.docs.map((doc) {
        final data = doc.data();
        final endTimestamp = data['endAt'];
        final options = List<String>.from(data['options'] ?? []);
        final votesRaw = List<dynamic>.from(data['votes'] ?? []);
        final votes = votesRaw.map((e) => (e as num).toInt()).toList();

        return PollItem(
          id: doc.id,
          question: data['question'] ?? '',
          options: options,
          votes: votes,
          endAt: endTimestamp is Timestamp
              ? endTimestamp.toDate()
              : DateTime.now(),
        );
      }).toList();

      firestorePolls.sort((a, b) => a.endAt.compareTo(b.endAt));
    } catch (_) {}

    return TwiixState(
      p,
      isLive: p.getBool('isLive') ?? false,
      news: firestoreNews ?? decodeList('news', NewsItem.fromJson, [
        NewsItem('Bienvenue dans le QG Les Twiix', 'La première vraie version de l’application communautaire démarre ici.'),
        NewsItem('Défi communautaire', 'Participe aux défis et cumule des Twiix Points.'),
      ]),
      lives: firestoreLives ?? decodeList('lives', LiveItem.fromJson, [
        LiveItem('Lundi', '17h00', 'Live TikTok'),
        LiveItem('Mercredi', '17h00', 'Live TikTok'),
        LiveItem('Vendredi', '20h30', 'MR Club Pro'),
      ]),
      donors: decodeList('donors', Donor.fromJson, [
        Donor('TwiixMaster', 3250), Donor('MaxTwiix', 2450), Donor('LaTeamTwiix', 2100), Donor('Fan2Twiix', 1870),
      ]),
      challenges: decodeList('challenges', Challenge.fromJson, [
        Challenge('Défi de la semaine', 'Twiix Dance', 150), Challenge('Clip du mois', 'Envoie ton meilleur clip', 100), Challenge('Quiz Twiix', '10 questions sur les lives', 80),
      ]),
      polls: firestorePolls,
    );
  }

  Future<void> _save() async {
    await prefs.setBool('isLive', isLive);
    await prefs.setString('news', jsonEncode(news.map((e) => e.toJson()).toList()));
    await prefs.setString('lives', jsonEncode(lives.map((e) => e.toJson()).toList()));
    await prefs.setString('donors', jsonEncode(donors.map((e) => e.toJson()).toList()));
    await prefs.setString('challenges', jsonEncode(challenges.map((e) => e.toJson()).toList()));
  }

  Future<void> addPoll(String question, List<String> options, DateTime endAt) async {
    final cleanOptions = options.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (question.trim().isEmpty || cleanOptions.length < 2) return;

    final ref = await FirebaseFirestore.instance.collection('polls').add({
      'question': question.trim(),
      'options': cleanOptions,
      'votes': List<int>.filled(cleanOptions.length, 0),
      'endAt': Timestamp.fromDate(endAt),
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });

    polls.add(PollItem(
      id: ref.id,
      question: question.trim(),
      options: cleanOptions,
      votes: List<int>.filled(cleanOptions.length, 0),
      endAt: endAt,
    ));
    polls.sort((a, b) => a.endAt.compareTo(b.endAt));
    notifyListeners();
  }

  Future<void> setLive(bool value) async { isLive = value; notifyListeners(); await _save(); }
  Future<void> addNews(String title, String body) async {
    await FirebaseFirestore.instance.collection('news').add({
      'title': title,
      'content': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    news.insert(0, NewsItem(title, body));
    notifyListeners();
  }
  Future<void> deleteNewsByTitle(String title) async {
    final snap = await FirebaseFirestore.instance.collection('news').where('title', isEqualTo: title).limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.delete();
      news.removeWhere((e) => e.title == title);
      notifyListeners();
    }
  }
  Future<void> addLive(String day, String time, String title, {DateTime? scheduledAt}) async { await FirebaseFirestore.instance.collection('lives').add({'day': day, 'time': time, 'title': title, 'active': true, 'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt) : null}); lives.add(LiveItem(day, time, title, scheduledAt: scheduledAt)); notifyListeners(); }
Future<void> deleteLive(String title, DateTime? scheduledAt) async {    Query query = FirebaseFirestore.instance.collection('lives').where('title', isEqualTo: title);    final snap = await query.get();    for (final doc in snap.docs) {      final data = doc.data() as Map<String, dynamic>;      final ts = data['scheduledAt'];      final dt = ts is Timestamp ? ts.toDate() : null;      if (scheduledAt == null || dt?.millisecondsSinceEpoch == scheduledAt.millisecondsSinceEpoch) {        await doc.reference.delete();        break;      }    }    lives.removeWhere((l) => l.title == title && (scheduledAt == null || l.scheduledAt?.millisecondsSinceEpoch == scheduledAt.millisecondsSinceEpoch));    notifyListeners();  }
  Future<void> deletePoll(String pollId) async {
    final pollRef = FirebaseFirestore.instance.collection('polls').doc(pollId);

    final votesSnapshot = await pollRef.collection('votes').get();
    final batch = FirebaseFirestore.instance.batch();

    for (final voteDoc in votesSnapshot.docs) {
      batch.delete(voteDoc.reference);
    }

    batch.delete(pollRef);
    await batch.commit();

    polls.removeWhere((poll) => poll.id == pollId);
    notifyListeners();
  }

  Future<void> addDonor(String name, int points) async { donors.add(Donor(name, points)); donors.sort((a,b) => b.points.compareTo(a.points)); notifyListeners(); await _save(); }
  Future<void> addChallenge(String title, String subtitle, int points) async { challenges.add(Challenge(title, subtitle, points)); notifyListeners(); await _save(); }
  Future<void> resetDemo() async { await prefs.clear(); notifyListeners(); }
}

class TwiixIntro extends StatefulWidget {
  final TwiixState state;

  const TwiixIntro({super.key, required this.state});

  @override
  State<TwiixIntro> createState() => _TwiixIntroState();
}

class _TwiixIntroState extends State<TwiixIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _step = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _playIntro();
  }

  Future<void> _playIntro() async {
    await Future.delayed(const Duration(milliseconds: 250));

    for (int step = 0; step < 3; step++) {
      if (!mounted) return;

      setState(() => _step = step);
      _controller
        ..reset()
        ..forward();

      await Future.delayed(
        Duration(milliseconds: step == 2 ? 850 : 650),
      );
    }

    if (!mounted) return;

    setState(() => _step = 3);
    _controller
      ..reset()
      ..forward();

    await Future.delayed(const Duration(milliseconds: 1100));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, secondaryAnimation) =>
            Shell(state: widget.state),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _counterText(String text) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.elasticOut.transform(_controller.value);

        return Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.35 + (0.65 * progress),
            child: child,
          ),
        );
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: text == 'ZIN !' ? 78 : 110,
          height: 1,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: text == 'ZIN !' ? 3 : 0,
          color: _step == 0 ? blue : pink,
          shadows: [
            Shadow(
              color: (_step == 0 ? blue : pink).withValues(alpha: 0.9),
              blurRadius: 25,
            ),
            Shadow(
              color: (_step == 0 ? blue : pink).withValues(alpha: 0.5),
              blurRadius: 55,
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoReveal() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeOutBack.transform(_controller.value);

        return Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.55 + (0.45 * progress),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: pink.withValues(alpha: 0.35),
                  blurRadius: 55,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: blue.withValues(alpha: 0.25),
                  blurRadius: 80,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_source.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Trois, deux, Zin !',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: pink,
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String counter = '3';

    if (_step == 1) {
      counter = '2';
    } else if (_step == 2) {
      counter = 'ZIN !';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    (_step == 0 ? blue : pink).withValues(alpha: 0.16),
                    const Color(0xFF050508),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: blue.withValues(alpha: 0.20),
                    blurRadius: 100,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pink.withValues(alpha: 0.20),
                    blurRadius: 100,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: _step < 3
                ? _counterText(counter)
                : _logoReveal(),
          ),
        ],
      ),
    );
  }
}
class Shell extends StatefulWidget {
  final TwiixState state;
  const Shell({super.key, required this.state});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final pages = [HomePage(state: widget.state, onNavigate: (i) => setState(() => index = i)), LivesPage(state: widget.state), ChallengesPage(state: widget.state), DonorsPage(state: widget.state), ProfilePage(state: widget.state)];
        return Scaffold(
          body: SafeArea(child: IndexedStack(index: index, children: pages)),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            backgroundColor: const Color(0xFF0D0D12),
            indicatorColor: const Color(0x33FF2C7D),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
              NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Lives'),
              NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Défis'),
              NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium), label: 'Donateurs'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        );
      },
    );
  }
}

class PageFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const PageFrame({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverAppBar(pinned: true, backgroundColor: const Color(0xFF07070B), title: Row(children: [
      const CircleAvatar(radius: 17, backgroundImage: AssetImage('assets/images/logo_source.jpg')),
      const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ])),
    SliverPadding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), sliver: SliverList(delegate: SliverChildListDelegate(children))),
  ]);
}

class HomePage extends StatelessWidget {
  final TwiixState state;
  final ValueChanged<int> onNavigate;
  const HomePage({super.key, required this.state, required this.onNavigate});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'LES TWIIX',
    children: [
      HeroCard(isLive: state.isLive),
      const SizedBox(height: 16),
      const SectionTitle('Prochain live'),
      if (state.lives.isNotEmpty)
        InfoCard(
          icon: Icons.schedule,
          title: '${state.lives.first.day} • ${state.lives.first.time}',
          subtitle: state.lives.first.title,
          trailing: 'Me rappeler',
        ),
      const SizedBox(height: 18),
      const SectionTitle('Le QG de la communauté'),
      Row(children: [
        Expanded(child: MiniAction(icon: Icons.forum_outlined, title: 'Communauté', subtitle: 'Actus & sondages', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: const Color(0xFF07070B), body: CommunityPage(state: state)))))),
        const SizedBox(width: 10),
        Expanded(child: MiniAction(icon: Icons.military_tech_outlined, title: 'Classement', subtitle: 'Twiix Points', onTap: () => onNavigate(2))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: MiniAction(icon: Icons.workspace_premium_outlined, title: 'Top donateurs', subtitle: 'Hall of Fame', onTap: () => onNavigate(3))),
        const SizedBox(width: 10),
        Expanded(child: MiniAction(icon: Icons.card_giftcard_outlined, title: 'Badges', subtitle: 'Récompenses', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(backgroundColor: Color(0xFF07070B), body: BadgesPage()))))),
      ]),
      const SizedBox(height: 18),
      const SectionTitle('Dernières actus'),
      ...state.news.take(5).map((n) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FeedCard(title: n.title, body: n.body),
      )),
    ],
  );
}

class HeroCard extends StatelessWidget {
  final bool isLive;
  const HeroCard({super.key, required this.isLive});
  @override Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), image: const DecorationImage(image: AssetImage('assets/images/planning_source.jpeg'), fit: BoxFit.cover), border: Border.all(color: const Color(0x55FF2C7D))),
    child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x22000000), Color(0xEE050509)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
      Chip(label: Text(isLive ? '● EN LIVE' : '● HORS LIVE', style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: isLive ? const Color(0xDDFF235D) : const Color(0xCC33333D)),
      const SizedBox(height: 6), Text(isLive ? 'ON EST EN LIVE !' : 'PROCHAINEMENT EN LIVE', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      Text(isLive ? 'Rejoins Les Twiix et la communauté maintenant.' : 'Retrouve le planning et active tes rappels.', style: const TextStyle(color: Colors.white70)),
    ])),
  );
}

class LivesPage extends StatelessWidget {
  final TwiixState state;
  const LivesPage({super.key, required this.state});
  @override Widget build(BuildContext context) => PageFrame(title: 'Planning des lives', children: [
    ...state.lives.where((l) => l.scheduledAt == null || l.scheduledAt!.isAfter(DateTime.now())).map((l) => Padding(padding: const EdgeInsets.only(bottom: 10), child: InfoCard(icon: Icons.live_tv, title: '${l.day} • ${l.time}', subtitle: l.title, trailing: 'Rappel'))),
  ]);
}

class ChallengesPage extends StatelessWidget {
  final TwiixState state;
  const ChallengesPage({super.key, required this.state});
  @override Widget build(BuildContext context) => PageFrame(title: 'Défis & Twiix Points', children: [
    ...state.challenges.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ChallengeCard(title: c.title, subtitle: c.subtitle, points: c.points))),
  ]);
}

class DonorsPage extends StatelessWidget {
  final TwiixState state;
  const DonorsPage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    final sorted = [...state.donors]..sort((a,b) => b.points.compareTo(a.points));
    return PageFrame(title: 'Hall of Fame', children: [
      const Text('TOP DONATEURS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6), const Text('Classement de démonstration', style: TextStyle(color: Colors.white60)), const SizedBox(height: 16),
      ...List.generate(sorted.length, (i) => DonorTile(rank: i + 1, donor: sorted[i])),
      const SizedBox(height: 18), const InfoCard(icon: Icons.privacy_tip_outlined, title: 'Respect de la vie privée', subtitle: 'Un donateur pourra masquer son montant ou choisir de ne pas apparaître publiquement.'),
    ]);
  }
}

class CommunityPage extends StatelessWidget {
  final TwiixState state;

  const CommunityPage({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final activePolls =
        state.polls.where((poll) => !poll.isFinished).toList();

    final finishedPolls =
        state.polls.where((poll) => poll.isFinished).toList();

    Widget sectionHeader(IconData icon, String text) {
      return Row(
        children: [
          Icon(icon, color: pink, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }


    return PageFrame(
      title: 'Communauté',
      children: [
        sectionHeader(Icons.poll_outlined, 'Sondages en cours'),
        const SizedBox(height: 10),

        if (activePolls.isEmpty)
          const InfoCard(
            icon: Icons.poll_outlined,
            title: 'Aucun sondage en cours',
            subtitle: 'Les prochains sondages apparaîtront ici.',
          )
        else
          ...activePolls.map(
            (poll) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PollCard(poll: poll, state: state),
            ),
          ),

        const SizedBox(height: 22),

        sectionHeader(Icons.campaign_outlined, 'Actualités'),
        const SizedBox(height: 10),

        if (state.news.isEmpty)
          const Text(
            'Aucune actualité pour le moment.',
            style: TextStyle(color: Colors.white60),
          )
        else
          ...state.news.map(
            (news) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FeedCard(
                title: news.title,
                body: news.body,
              ),
            ),
          ),

        if (finishedPolls.isNotEmpty) ...[
          const SizedBox(height: 22),
          sectionHeader(Icons.history_rounded, 'Sondages terminés'),
          const SizedBox(height: 10),

          ...finishedPolls.map(
            (poll) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PollCard(poll: poll, state: state),
            ),
          ),
        ],
      ],
    );
  }
}
class PollCard extends StatefulWidget {
  final PollItem poll;
  final TwiixState state;
  const PollCard({super.key, required this.poll, required this.state});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  late final Future<bool> _canManageFuture;

  @override
  void initState() {
    super.initState();
    _canManageFuture = canManagePoll();
  }

  Future<void> vote(int optionIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.poll.isFinished) return;

    bool unlockedFirstVote = false;

    final voteRef = FirebaseFirestore.instance
        .collection('polls')
        .doc(widget.poll.id)
        .collection('votes')
        .doc(user.uid);

    try {
      final existingVote = await voteRef.get();

      if (existingVote.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu as déjà voté à ce sondage.'),
          ),
        );
        return;
      }

      await voteRef.set({
        'optionIndex': optionIndex,
        'votedAt': FieldValue.serverTimestamp(),
      });

      if (!user.isAnonymous) {
        try {
          final badgeRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('badges')
              .doc('first_vote');

          final badgeSnapshot = await badgeRef.get();

          if (!badgeSnapshot.exists) {
            await badgeRef.set({
              'id': 'first_vote',
              'sourcePollId': widget.poll.id,
              'unlockedAt': FieldValue.serverTimestamp(),
            });

            unlockedFirstVote = true;
          }
        } catch (_) {
          // Le vote reste valide même si le badge ne peut pas être créé.
        }
      }

      if (!mounted) return;

      if (unlockedFirstVote) {
        await showBadgeUnlockAnimation();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote enregistré !'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’enregistrer le vote.'),
        ),
      );
    }
  }

  Future<void> showBadgeUnlockAnimation() async {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    final dialogFuture = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Badge débloqué',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
              decoration: BoxDecoration(
                color: const Color(0xFF121218),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: pink.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: pink.withValues(alpha: 0.30),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BADGE DÉBLOQUÉ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 22),
                  Icon(
                    Icons.how_to_vote_rounded,
                    size: 90,
                    color: pink,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Premier vote',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tu viens de débloquer ton premier badge Twiix !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeIn,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.45,
              end: 1,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 2600));

    if (mounted && navigator.canPop()) {
      navigator.pop();
    }

    await dialogFuture;
  }

  Future<bool> canManagePoll() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      return false;
    }

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      final data = adminDoc.data();
      final active = data?['active'] == true;
      final role = data?['role'];

      return active && (role == 'owner' || role == 'twiix');
    } catch (_) {
      return false;
    }
  }

  Future<void> confirmDeletePoll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce sondage ?'),
        content: Text(
          '${widget.poll.question}\n\nLes votes associés seront également supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.state.deletePoll(widget.poll.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sondage supprimé.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer le sondage.'),
        ),
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get votesStream {
    return FirebaseFirestore.instance
        .collection('polls')
        .doc(widget.poll.id)
        .collection('votes')
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    final finished = widget.poll.isFinished;
    final end = widget.poll.endAt;
    final endText =
        '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year} à ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: votesStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final currentUid = FirebaseAuth.instance.currentUser?.uid;

        final voteCounts = List<int>.filled(widget.poll.options.length, 0);
        int? myVote;

        for (final doc in docs) {
          final optionIndex = doc.data()['optionIndex'];

          if (optionIndex is int &&
              optionIndex >= 0 &&
              optionIndex < voteCounts.length) {
            voteCounts[optionIndex]++;

            if (doc.id == currentUid) {
              myVote = optionIndex;
            }
          }
        }

        final totalVotes =
            voteCounts.fold<int>(0, (total, value) => total + value);

        final hasVoted = myVote != null;
        final showResults = finished || hasVoted;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0x22FF2C7D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.poll_outlined,
                        color: pink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.poll.question,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            finished
                                ? 'Sondage terminé'
                                : hasVoted
                                    ? 'Vote enregistré • Fin : $endText'
                                    : 'Fin : $endText',
                            style: TextStyle(
                              color: finished
                                  ? Colors.white38
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<bool>(
                      future: _canManageFuture,
                      builder: (context, adminSnapshot) {
                        if (adminSnapshot.data != true) {
                          return const SizedBox.shrink();
                        }

                        return IconButton(
                          tooltip: 'Supprimer le sondage',
                          visualDensity: VisualDensity.compact,
                          onPressed: confirmDeletePoll,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white38,
                            size: 21,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

              ...List.generate(widget.poll.options.length, (i) {
                final votes = voteCounts[i];
                final percent = totalVotes == 0
                    ? 0
                    : ((votes / totalVotes) * 100).round();

                  if (showResults) {
                    final isMyVote = myVote == i;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15151C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isMyVote
                                  ? pink
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isMyVote ? 1.3 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.poll.options[i],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (isMyVote) ...[
                                      const SizedBox(height: 5),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: pink,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Ton vote',
                                            style: TextStyle(
                                              color: pink,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: isMyVote ? pink : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => vote(i),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        alignment: Alignment.centerLeft,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.poll.options[i],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),

                if (showResults)
                  Text(
                    '$totalVotes vote${totalVotes > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}


class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  static const badges = [
    {
      'id': 'first_vote',
      'title': 'Premier vote',
      'description': 'Tu as participé à ton premier sondage Twiix.',
      'howTo': 'Participe à ton premier sondage de la communauté.',
      'icon': Icons.how_to_vote_rounded,
    },
    {
      'id': 'polls_10',
      'title': 'Habitué des sondages',
      'description': 'Tu participes régulièrement aux sondages Twiix.',
      'howTo': 'Participe à 10 sondages différents.',
      'icon': Icons.poll_rounded,
    },
    {
      'id': 'first_challenge',
      'title': 'Premier défi',
      'description': 'Tu as relevé ton premier défi Twiix.',
      'howTo': 'Participe à ton premier défi.',
      'icon': Icons.sports_esports_rounded,
    },
    {
      'id': 'challenges_10',
      'title': 'Compétiteur',
      'description': 'Les défis Twiix n’ont presque plus de secret pour toi.',
      'howTo': 'Participe à 10 défis différents.',
      'icon': Icons.emoji_events_rounded,
    },
    {
      'id': 'first_event',
      'title': 'Présent au rendez-vous',
      'description': 'Tu as participé à ton premier événement Twiix.',
      'howTo': 'Participe à ton premier événement Twiix.',
      'icon': Icons.event_available_rounded,
    },
    {
      'id': 'twiix_supporter',
      'title': 'Supporter Twiix',
      'description': 'Tu fais partie des membres fidèles de la communauté.',
      'howTo': 'Condition spéciale à découvrir prochainement.',
      'icon': Icons.shield_rounded,
    },
  ];

  void showBadgeDetails(
    BuildContext context,
    Map<String, Object> badge,
    bool unlocked,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badge['icon'] as IconData,
              size: 72,
              color: unlocked ? pink : Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              badge['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge['description'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              unlocked ? 'Débloqué' : 'Comment le débloquer',
              style: TextStyle(
                color: unlocked ? pink : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge['howTo'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return PageFrame(
      title: 'Badges & Récompenses',
      children: [
        if (user == null)
          const InfoCard(
            icon: Icons.lock_outline,
            title: 'Connexion requise',
            subtitle: 'Connecte-toi pour voir ta collection de badges.',
          )
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('badges')
                .snapshots(),
            builder: (context, snapshot) {
              final unlockedIds =
                  snapshot.data?.docs.map((doc) => doc.id).toSet() ?? <String>{};

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: badges.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  final unlocked =
                      unlockedIds.contains(badge['id'] as String);

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => showBadgeDetails(
                      context,
                      badge,
                      unlocked,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121218),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: unlocked
                              ? pink.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.42,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  badge['icon'] as IconData,
                                  size: 56,
                                  color: unlocked ? pink : Colors.white70,
                                ),
                                if (!unlocked)
                                  const Positioned(
                                    right: -8,
                                    bottom: -5,
                                    child: Icon(
                                      Icons.lock_rounded,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              badge['title'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}


class ProfilePage extends StatelessWidget {
  final TwiixState state;
  const ProfilePage({super.key, required this.state});

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> openAdmin(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.isAnonymous) {
      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();

        final data = adminDoc.data();
        final active = data?['active'] == true;
        final role = data?['role'];
        final allowed = active && (role == 'owner' || role == 'twiix');

        if (allowed) {
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPage(state: state),
            ),
          );
          return;
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce compte n’a pas accès à l’espace Admin.'),
          ),
        );
        return;
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de vérifier les droits Admin.'),
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLoginPage(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data ?? FirebaseAuth.instance.currentUser;
        final isMember = user != null && !user.isAnonymous;

        if (!isMember) {
          return PageFrame(
            title: 'Mon profil',
            children: [
              const Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundImage: AssetImage('assets/images/logo_source.jpg'),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Membre Twiix',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Crée ton compte pour débloquer ton profil',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberSignupPage()),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('Créer mon compte Twiix'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberLoginPage()),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Se connecter à mon compte Twiix'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                  onPressed: () => openAdmin(context),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Accès Admin / Twiix'),
              ),
            ],
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            final data = profileSnapshot.data?.data() ?? <String, dynamic>{};
            final pseudo = (data['pseudo'] as String?)?.trim();
            final displayPseudo = pseudo != null && pseudo.isNotEmpty
                ? pseudo
                : (user.displayName ?? 'Membre Twiix');
            final points = (data['twiixPoints'] as num?)?.toInt() ?? 0;

            return PageFrame(
              title: 'Mon profil',
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 58,
                        backgroundImage: AssetImage('assets/images/logo_source.jpg'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayPseudo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: cardDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: pink, size: 34),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Twiix Points',
                            style: TextStyle(color: Colors.white60),
                          ),
                          Text(
                            '$points',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionTitle('Mes badges'),
                const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('badges')
                        .snapshots(),
                    builder: (context, badgesSnapshot) {
                      final badgeDocs = badgesSnapshot.data?.docs ?? [];
                      final hasFirstVote = badgeDocs.any(
                        (doc) => doc.id == 'first_vote',
                      );

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: cardDecoration(),
                        child: hasFirstVote
                            ? Row(
                                children: [
                                  const Icon(
                                    Icons.how_to_vote_rounded,
                                    color: pink,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Premier vote',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Tu as participé à ton premier sondage Twiix.',
                                          style: TextStyle(
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                children: [
                                  Icon(
                                    Icons.workspace_premium_outlined,
                                    size: 42,
                                    color: pink,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Aucun badge débloqué pour le moment',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Participe aux sondages, défis et événements pour gagner des badges.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                    onPressed: () => openAdmin(context),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Accès Admin / Twiix'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    await logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class MemberLoginPage extends StatefulWidget {
  const MemberLoginPage({super.key});

  @override
  State<MemberLoginPage> createState() => _MemberLoginPageState();
}

class _MemberLoginPageState extends State<MemberLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => error = e.message ?? 'Connexion impossible.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => error = 'Entre ton adresse e-mail pour réinitialiser ton mot de passe.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de réinitialisation envoyé.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'invalid-email') {
          error = 'Adresse e-mail invalide.';
        } else {
          error = e.message ?? 'Impossible d’envoyer l’e-mail de réinitialisation.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connexion membre')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Adresse e-mail'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: forgotPassword,
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          const SizedBox(height: 18),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : login,
            icon: const Icon(Icons.login),
            label: Text(loading ? 'Connexion...' : 'Se connecter'),
          ),
        ],
      ),
    ),
  );
}

class MemberSignupPage extends StatefulWidget {
  const MemberSignupPage({super.key});

  @override
  State<MemberSignupPage> createState() => _MemberSignupPageState();
}

class _MemberSignupPageState extends State<MemberSignupPage> {
  final pseudoController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> signup() async {
    final pseudo = pseudoController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (pseudo.isEmpty || email.isEmpty || password.length < 6) {
      setState(() => error = 'Remplis tous les champs. Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      UserCredential result;
      final currentUser = auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        result = await currentUser.linkWithCredential(credential);
      } else {
        result = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final user = result.user!;
      await user.updateDisplayName(pseudo);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'pseudo': pseudo,
        'email': email,
        'photoUrl': '',
        'twiixPoints': 0,
        'featuredBadgeId': null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          error = 'Cette adresse e-mail possède déjà un compte.';
        } else if (e.code == 'weak-password') {
          error = 'Le mot de passe est trop faible.';
        } else if (e.code == 'invalid-email') {
          error = 'Adresse e-mail invalide.';
        } else {
          error = e.message ?? 'Inscription impossible.';
        }
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Créer mon compte')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: pseudoController,
            decoration: const InputDecoration(labelText: 'Pseudo'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Adresse e-mail'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          const SizedBox(height: 18),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
            ),
          FilledButton.icon(
            onPressed: loading ? null : signup,
            icon: const Icon(Icons.person_add),
            label: Text(loading ? 'Création...' : 'Créer mon compte Twiix'),
          ),
        ],
      ),
    ),
  );
}


class AdminLoginPage extends StatefulWidget {
  final TwiixState state;
  const AdminLoginPage({super.key, required this.state});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = credential.user!.uid;
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      final data = adminDoc.data();
      final active = data?['active'] == true;
      final role = data?['role'];
      final allowed = active && (role == 'owner' || role == 'twiix');

      if (!allowed) {
        await FirebaseAuth.instance.signOut();
          await FirebaseAuth.instance.signInAnonymously();
        if (!mounted) return;
        setState(() => error = 'Ce compte n’a pas accès à l’espace Admin.');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminPage(state: widget.state),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => error = e.message ?? 'Connexion impossible.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Impossible de vérifier les droits Admin.');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Admin')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
              ),
            ),
            const SizedBox(height: 20),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loading ? null : login,
              child: Text(loading ? 'Connexion...' : 'Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
class AdminPage extends StatelessWidget {
  final TwiixState state;
  const AdminPage({super.key, required this.state});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Twiix Admin • Démo')),
    body: ListenableBuilder(listenable: state, builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(16), decoration: cardDecoration(), child: SwitchListTile(contentPadding: EdgeInsets.zero, value: state.isLive, onChanged: state.setLive, title: const Text('Statut LIVE', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(state.isLive ? 'La communauté voit “EN LIVE”.' : 'La communauté voit “HORS LIVE”.'))),
      const SizedBox(height: 12),
      AdminAction(icon: Icons.campaign, title: 'Publier une actualité', onTap: () => _newsDialog(context, state)),
      AdminAction(icon: Icons.delete_outline, title: 'Gérer les actualités', onTap: () => _manageNewsDialog(context, state)),
      AdminAction(icon: Icons.calendar_month, title: 'Ajouter un live', onTap: () => _liveDialog(context, state)),
      AdminAction(icon: Icons.delete_outline, title: 'Gérer les lives', onTap: () => _manageLivesDialog(context, state)),
      AdminAction(icon: Icons.workspace_premium, title: 'Ajouter un donateur', onTap: () => _donorDialog(context, state)),
      AdminAction(icon: Icons.emoji_events, title: 'Créer un défi', onTap: () => _challengeDialog(context, state)),
      AdminAction(icon: Icons.poll_outlined, title: 'Créer un sondage', onTap: () => _pollDialog(context, state)),
      const SizedBox(height: 18),
      const Text('Cette V0.2 enregistre les changements sur ce téléphone uniquement. La prochaine étape connectera cet écran à une base en ligne sécurisée pour que les deux admins modifient l’app de toute la communauté.', style: TextStyle(color: Colors.white60)),
    ])),
  );
}

Future<void> _newsDialog(BuildContext context, TwiixState state) async {
  final a = TextEditingController(), b = TextEditingController();
  await _formDialog(context, 'Nouvelle actualité', [('Titre', a), ('Message', b)], () async { if (a.text.trim().isNotEmpty && b.text.trim().isNotEmpty) await state.addNews(a.text.trim(), b.text.trim()); });
}
Future<void> _liveDialog(BuildContext context, TwiixState state) async {
  final titleController = TextEditingController();
  final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
  if (date == null) return;
  if (!context.mounted) return;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
  if (time == null) return;
  final scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  final day = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  final hour = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  await _formDialog(context, 'Ajouter un live', [('Titre', titleController)], () async {
    if (titleController.text.trim().isNotEmpty) await state.addLive(day, hour, titleController.text.trim(), scheduledAt: scheduledAt);
  });
}
Future<void> _donorDialog(BuildContext context, TwiixState state) async {
  final a = TextEditingController(), b = TextEditingController();
  await _formDialog(context, 'Ajouter un donateur', [('Pseudo', a), ('Points', b)], () async { final pts = int.tryParse(b.text.trim()) ?? 0; if (a.text.trim().isNotEmpty) await state.addDonor(a.text.trim(), pts); });
}
Future<void> _challengeDialog(BuildContext context, TwiixState state) async {
  final a = TextEditingController(), b = TextEditingController(), c = TextEditingController();
  await _formDialog(context, 'Créer un défi', [('Nom', a), ('Description', b), ('Points', c)], () async { final pts = int.tryParse(c.text.trim()) ?? 0; if (a.text.trim().isNotEmpty) await state.addChallenge(a.text.trim(), b.text.trim(), pts); });
}

Future<void> _pollDialog(BuildContext context, TwiixState state) async {
  final question = TextEditingController();
  final option1 = TextEditingController();
  final option2 = TextEditingController();
  final option3 = TextEditingController();
  final option4 = TextEditingController();

  final date = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  if (date == null) return;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (time == null) return;

  final endAt = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );

  await _formDialog(
    context,
    'Créer un sondage',
    [
      ('Question', question),
      ('Réponse 1', option1),
      ('Réponse 2', option2),
      ('Réponse 3 (optionnelle)', option3),
      ('Réponse 4 (optionnelle)', option4),
    ],
    () async {
      await state.addPoll(
        question.text.trim(),
        [
          option1.text.trim(),
          option2.text.trim(),
          option3.text.trim(),
          option4.text.trim(),
        ],
        endAt,
      );
    },
  );
}


Future<void> _formDialog(BuildContext context, String title, List<(String, TextEditingController)> fields, Future<void> Function() save) async {
  await showDialog(context: context, builder: (dialogContext) => AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: f.$2, decoration: InputDecoration(labelText: f.$1)))).toList())),
    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')), FilledButton(onPressed: () async { await save(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('Publier'))],
  ));
}

class AdminAction extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const AdminAction({super.key, required this.icon, required this.title, required this.onTap});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ListTile(onTap: onTap, tileColor: const Color(0xFF111117), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), leading: CircleAvatar(backgroundColor: const Color(0x22FF2C7D), child: Icon(icon, color: pink)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right)));
}

class SectionTitle extends StatelessWidget {
  final String text; const SectionTitle(this.text, {super.key});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)));
}
class InfoCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final String? trailing;
  const InfoCard({super.key, required this.icon, required this.title, required this.subtitle, this.trailing});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: cardDecoration(), child: Row(children: [CircleAvatar(backgroundColor: const Color(0x22FF2C7D), child: Icon(icon, color: pink)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Colors.white60))])), if (trailing != null) Text(trailing!, style: const TextStyle(color: pink, fontWeight: FontWeight.w700))]));
}
class MiniAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const MiniAction({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: pink),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    ),
  );
}
class FeedCard extends StatelessWidget {
  final String title;
  final String body;

  const FeedCard({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage:
                    AssetImage('assets/images/logo_source.jpg'),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Twiix Officiel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.verified,
                      color: pink,
                      size: 16,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x22FF2C7D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'OFFICIEL',
                  style: TextStyle(
                    color: pink,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
class ChallengeCard extends StatelessWidget {
  final String title; final String subtitle; final int points;
  const ChallengeCard({super.key, required this.title, required this.subtitle, required this.points});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: cardDecoration(), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.white60))])), Text('+$points pts', style: const TextStyle(color: Color(0xFFFFD34E), fontWeight: FontWeight.w900))]));
}
class DonorTile extends StatelessWidget {
  final int rank; final Donor donor;
  const DonorTile({super.key, required this.rank, required this.donor});
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14), decoration: cardDecoration(), child: Row(children: [SizedBox(width: 34, child: Text('$rank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: rank <= 3 ? const Color(0xFFFFD34E) : Colors.white70))), const CircleAvatar(radius: 19, backgroundImage: AssetImage('assets/images/logo_source.jpg')), const SizedBox(width: 11), Expanded(child: Text(donor.name, style: const TextStyle(fontWeight: FontWeight.w800))), Text('${donor.points} pts', style: const TextStyle(color: pink, fontWeight: FontWeight.w800))]));
}

BoxDecoration cardDecoration() => BoxDecoration(color: const Color(0xFF111117), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x22FFFFFF)));

Future<void> _manageNewsDialog(BuildContext context, TwiixState state) async {
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Gérer les actualités'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) => ListView.builder(
            shrinkWrap: true,
            itemCount: state.news.length,
            itemBuilder: (context, i) {
              final item = state.news[i];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.body),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (confirmContext) => AlertDialog(
                        title: const Text('Supprimer cette actualité ?'),
                        content: Text(item.title),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(confirmContext, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(confirmContext, true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    if (ok == true) {
                      await state.deleteNewsByTitle(item.title);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

Future<void> _manageLivesDialog(BuildContext context, TwiixState state) async {
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Gérer les lives'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) => ListView.builder(
            shrinkWrap: true,
            itemCount: state.lives.length,
            itemBuilder: (context, i) {
              final live = state.lives[i];
              return ListTile(
                title: Text(live.title),
                subtitle: Text('${live.day} • ${live.time}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (confirmContext) => AlertDialog(
                        title: const Text('Supprimer ce live ?'),
                        content: Text('${live.title}\n${live.day} • ${live.time}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(confirmContext, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(confirmContext, true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    if (ok == true) {
                      await state.deleteLive(live.title, live.scheduledAt);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
