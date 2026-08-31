import 'package:flutter/material.dart';

void main() => runApp(const TwiixApp());

class TwiixApp extends StatelessWidget {
  const TwiixApp({super.key});

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2C7D);
    const blue = Color(0xFF3C7CFF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Les Twiix',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07070B),
        colorScheme: const ColorScheme.dark(
          primary: pink,
          secondary: blue,
          surface: Color(0xFF111117),
        ),
        useMaterial3: true,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  final pages = const [
    HomePage(),
    LivesPage(),
    ChallengesPage(),
    DonorsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
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
  }
}

class PageFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const PageFrame({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF07070B).withValues(alpha: .95),
          title: Row(children: [
            const CircleAvatar(radius: 17, backgroundImage: AssetImage('assets/images/logo_source.jpg')),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageFrame(title: 'LES TWIIX', children: [
      const HeroCard(),
      const SizedBox(height: 14),
      const SectionTitle('Prochain live'),
      const InfoCard(
        icon: Icons.schedule,
        title: 'Mercredi • 17h00',
        subtitle: 'Live TikTok — on se retrouve pour un nouveau rendez-vous.',
        trailing: 'Me rappeler',
      ),
      const SizedBox(height: 18),
      const SectionTitle('Le QG de la communauté'),
      Row(children: const [
        Expanded(child: MiniAction(icon: Icons.forum_outlined, title: 'Communauté', subtitle: 'Actus & sondages')),
        SizedBox(width: 10),
        Expanded(child: MiniAction(icon: Icons.military_tech_outlined, title: 'Classement', subtitle: 'Twiix Points')),
      ]),
      const SizedBox(height: 10),
      Row(children: const [
        Expanded(child: MiniAction(icon: Icons.workspace_premium_outlined, title: 'Top donateurs', subtitle: 'Hall of Fame')),
        SizedBox(width: 10),
        Expanded(child: MiniAction(icon: Icons.card_giftcard_outlined, title: 'Badges', subtitle: 'Récompenses')),
      ]),
      const SizedBox(height: 18),
      const SectionTitle('Dernières actus'),
      const FeedCard(title: 'Nouveau défi communautaire', body: 'Le défi de la semaine est lancé. Participe et gagne des Twiix Points !', likes: 256),
      const SizedBox(height: 10),
      const FeedCard(title: 'Planning mis à jour', body: 'Retrouve tous les prochains lives directement dans l’application.', likes: 143),
    ]);
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(image: AssetImage('assets/images/planning_source.jpeg'), fit: BoxFit.cover, alignment: Alignment.center),
        border: Border.all(color: const Color(0x55FF2C7D)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x22000000), Color(0xEE050509)]),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
          Chip(label: Text('● EN LIVE', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Color(0xDDFF235D)),
          SizedBox(height: 6),
          Text('ON EST EN LIVE !', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          Text('Rejoins Les Twiix et la communauté maintenant.', style: TextStyle(color: Colors.white70)),
        ]),
      ),
    );
  }
}

class LivesPage extends StatelessWidget {
  const LivesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageFrame(title: 'Planning des lives', children: const [
      InfoCard(icon: Icons.live_tv, title: 'Lundi • 17h', subtitle: 'Live TikTok', trailing: 'Rappel'),
      SizedBox(height: 10),
      InfoCard(icon: Icons.bedtime_outlined, title: 'Mardi', subtitle: 'Repos'),
      SizedBox(height: 10),
      InfoCard(icon: Icons.live_tv, title: 'Mercredi • 17h', subtitle: 'Live TikTok', trailing: 'Rappel'),
      SizedBox(height: 10),
      InfoCard(icon: Icons.bedtime_outlined, title: 'Jeudi', subtitle: 'Repos'),
      SizedBox(height: 10),
      InfoCard(icon: Icons.sports_esports, title: 'Vendredi', subtitle: 'Z Event — MR Club Pro'),
      SizedBox(height: 10),
      InfoCard(icon: Icons.sports_esports, title: 'Samedi', subtitle: 'Z Event — MR Club Pro'),
      SizedBox(height: 10),
      InfoCard(icon: Icons.sports_esports, title: 'Dimanche', subtitle: 'Z Event — MR Club Pro'),
    ]);
  }
}

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageFrame(title: 'Défis & Twiix Points', children: const [
      ChallengeCard(title: 'Défi de la semaine', subtitle: 'Twiix Dance', points: 150, progress: .72),
      SizedBox(height: 12),
      ChallengeCard(title: 'Clip du mois', subtitle: 'Envoie ton meilleur clip', points: 100, progress: .45),
      SizedBox(height: 12),
      ChallengeCard(title: 'Quiz Twiix', subtitle: '10 questions sur les lives', points: 80, progress: .2),
    ]);
  }
}

class DonorsPage extends StatelessWidget {
  const DonorsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageFrame(title: 'Hall of Fame', children: const [
      Text('TOP DONATEURS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      SizedBox(height: 6),
      Text('Classement de démonstration — semaine en cours', style: TextStyle(color: Colors.white60)),
      SizedBox(height: 16),
      DonorTile(rank: 1, name: 'TwiixMaster', score: '3 250 pts', badge: '👑'),
      DonorTile(rank: 2, name: 'MaxTwiix', score: '2 450 pts', badge: '💎'),
      DonorTile(rank: 3, name: 'LaTeamTwiix', score: '2 100 pts', badge: '🔥'),
      DonorTile(rank: 4, name: 'Fan2Twiix', score: '1 870 pts'),
      DonorTile(rank: 5, name: 'TwiixFamily', score: '1 560 pts'),
      SizedBox(height: 18),
      InfoCard(icon: Icons.privacy_tip_outlined, title: 'Respect de la vie privée', subtitle: 'Un donateur pourra choisir de masquer son montant ou de ne pas apparaître publiquement.'),
    ]);
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageFrame(title: 'Profil', children: [
      Center(child: Column(children: const [
        CircleAvatar(radius: 54, backgroundImage: AssetImage('assets/images/logo_source.jpg')),
        SizedBox(height: 12),
        Text('MaxTwiix', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text('Niveau 12 • 2 450 Twiix Points', style: TextStyle(color: Colors.white60)),
      ])),
      const SizedBox(height: 18),
      Row(children: const [
        Expanded(child: StatBox(value: '2 450', label: 'Points')),
        SizedBox(width: 8),
        Expanded(child: StatBox(value: '47', label: 'Badges')),
        SizedBox(width: 8),
        Expanded(child: StatBox(value: '15', label: 'Défis')),
      ]),
      const SizedBox(height: 18),
      const InfoCard(icon: Icons.admin_panel_settings_outlined, title: 'Espace Admin (démo)', subtitle: 'Planning, actualités, défis, notifications, Top donateurs et modération.', trailing: 'Ouvrir'),
      const SizedBox(height: 10),
      const InfoCard(icon: Icons.notifications_active_outlined, title: 'Notifications', subtitle: 'Lives, annonces importantes et résultats des défis.'),
      const SizedBox(height: 10),
      const InfoCard(icon: Icons.verified_user_outlined, title: 'Sécurité & modération', subtitle: 'Signalement, blocage et outils de modération prévus pour la version connectée.'),
    ]);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
  );
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  const InfoCard({super.key, required this.icon, required this.title, required this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(),
      child: Row(children: [
        CircleAvatar(backgroundColor: const Color(0x22FF2C7D), child: Icon(icon, color: const Color(0xFFFF2C7D))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: Colors.white60)),
        ])),
        if (trailing != null) Text(trailing!, style: const TextStyle(color: Color(0xFFFF2C7D), fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class MiniAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const MiniAction({super.key, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: cardDecoration(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFFFF2C7D)),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]),
  );
}

class FeedCard extends StatelessWidget {
  final String title;
  final String body;
  final int likes;
  const FeedCard({super.key, required this.title, required this.body, required this.likes});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: cardDecoration(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/logo_source.jpg')), SizedBox(width: 9), Text('Twiix Officiel', style: TextStyle(fontWeight: FontWeight.w800))]),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text(body, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 12),
      Row(children: [const Icon(Icons.favorite, size: 18, color: Color(0xFFFF2C7D)), const SizedBox(width: 6), Text('$likes'), const SizedBox(width: 18), const Icon(Icons.chat_bubble_outline, size: 18), const SizedBox(width: 6), const Text('23')]),
    ]),
  );
}

class ChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int points;
  final double progress;
  const ChallengeCard({super.key, required this.title, required this.subtitle, required this.points, required this.progress});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: cardDecoration(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))), Text('+$points pts', style: const TextStyle(color: Color(0xFFFFD34E), fontWeight: FontWeight.w900))]),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 14),
      LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(10)),
    ]),
  );
}

class DonorTile extends StatelessWidget {
  final int rank;
  final String name;
  final String score;
  final String? badge;
  const DonorTile({super.key, required this.rank, required this.name, required this.score, this.badge});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: cardDecoration(),
    child: Row(children: [
      SizedBox(width: 34, child: Text('$rank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: rank <= 3 ? const Color(0xFFFFD34E) : Colors.white70))),
      const CircleAvatar(radius: 19, backgroundImage: AssetImage('assets/images/logo_source.jpg')),
      const SizedBox(width: 11),
      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
      if (badge != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(badge!)),
      Text(score, style: const TextStyle(color: Color(0xFFFF2C7D), fontWeight: FontWeight.w800)),
    ]),
  );
}

class StatBox extends StatelessWidget {
  final String value;
  final String label;
  const StatBox({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: cardDecoration(),
    child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]),
  );
}

BoxDecoration cardDecoration() => BoxDecoration(
  color: const Color(0xFF111117),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0x22FFFFFF)),
);
