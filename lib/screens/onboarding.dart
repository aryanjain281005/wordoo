import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/lang.dart';
import '../screening/models.dart' as scr;
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

/// Minimal, transparent grown-up setup in three steps.
class ParentOnboarding extends StatefulWidget {
  const ParentOnboarding({super.key});
  @override
  State<ParentOnboarding> createState() => _ParentOnboardingState();
}

class _ParentOnboardingState extends State<ParentOnboarding> {
  int step = 0;
  final name = TextEditingController();
  int age = 6;
  String grade = 'Class 1';
  String lang = 'en';
  bool guardian = false, consentData = false, voice = false;
  late scr.Background bg;

  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    name.text = st.childName;
    age = st.age;
    grade = st.grade;
    lang = st.langCode;
    guardian = st.consent;
    consentData = st.consent;
    bg = scr.Background.fromJson(st.background.toJson());
    voice = bg.voiceConsent;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  bool get canNext => switch (step) { 0 => name.text.trim().isNotEmpty, 1 => guardian && consentData, _ => true };

  void _next() {
    final st = context.read<AppState>();
    if (step < 3) {
      setState(() => step++);
    } else {
      bg.voiceConsent = voice;
      st.saveBackground(bg);
      st.saveParentSetup(name: name.text, age: age, grade: grade, lang: lang, consent: true);
      st.go(AppScreen.avatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    return AdventureBackground(
      scene: Scene.forest,
      calm: true,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                Pop(child: Companion(type: 0, size: 84, message: ['Hi grown-up! Tell me about your explorer.', 'Your privacy matters to us.', 'A few quick questions help us read the results fairly.', 'Here is how our adventure works!'][step], speakLocale: null)),
                const SizedBox(height: 8),
                Panel(
                  color: const Color(0xFFFFFDF5),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      GestureDetector(onTap: () => step == 0 ? st.go(AppScreen.landing) : setState(() => step--), child: const Icon(Icons.arrow_back_rounded, size: 30, color: C.purple)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Let’s set up your child’s adventure!', style: ts(20, h: 1.15))),
                      const Icon(Icons.star_rounded, color: C.gold, size: 30),
                    ]),
                    const SizedBox(height: 14),
                    _Progress(step: step),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(key: ValueKey(step), child: [_step1(), _step2(), _stepBackground(), _step3()][step]),
                    ),
                    const SizedBox(height: 20),
                    Center(child: BigButton(label: step == 3 ? 'Create the Explorer' : 'Continue', icon: Icons.arrow_forward_rounded, width: 320, onTap: canNext ? _next : null)),
                  ]),
                ),
                if (step == 0) ...[
                  const SizedBox(height: 14),
                  Panel(
                    color: Colors.white.withValues(alpha: .9),
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      Text('Presenting? Try a ready-made explorer', style: ts(15, color: C.inkSoft)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: [
                        BigButton(label: 'Aarav • Profile A', style: BtnStyle.soft, height: 48, fontSize: 15, onTap: () => st.loadDemoProfile(0)),
                        BigButton(label: 'Meera • Profile B', style: BtnStyle.soft, height: 48, fontSize: 15, onTap: () => st.loadDemoProfile(1)),
                      ]),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text(t, style: ts(16, color: C.inkSoft)));

  Widget _chip(String t, bool sel, VoidCallback f, {bool enabled = true}) => GestureDetector(
        onTap: enabled ? f : null,
        child: Opacity(
          opacity: enabled ? 1 : .45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(color: sel ? C.purple : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.purple, width: 2.5)),
            child: Text(t, style: ts(18, color: sel ? Colors.white : C.purple)),
          ),
        ),
      );

  Widget _step1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Child’s name or nickname'),
        TextField(
          controller: name,
          onChanged: (_) => setState(() {}),
          style: ts(22),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: 'e.g. Aarav', filled: true, fillColor: const Color(0xFFF4F1FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(18)),
        ),
        _label('Age'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final a in [5, 6, 7, 8, 9, 10]) _chip('$a', age == a, () => setState(() => age = a))]),
        _label('Class / grade'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final g in ['Pre-school', 'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5']) _chip(g, grade == g, () => setState(() => grade = g))]),
        _label('Preferred language'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final l in LangRegistry.all) _chip(l.available ? l.native : '${l.name} · soon', lang == l.code, () => setState(() => lang = l.code), enabled: l.available),
        ]),
      ]);

  Widget _step2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Privacy & consent', style: ts(21)),
        const SizedBox(height: 10),
        _bullet('✅', 'We keep: nickname, age/class, language and practice results — on this device only.'),
        _bullet('🚫', 'We never ask for: phone number, location, photos, Aadhaar or any ID.'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.sky.withValues(alpha: .15), borderRadius: BorderRadius.circular(18)),
          child: Text('Readle helps identify reading and writing skills that may need more practice. It does not diagnose learning disabilities.', style: ts(15, w: FontWeight.w600, h: 1.35)),
        ),
        const SizedBox(height: 10),
        _check('I am the parent / guardian', guardian, (v) => setState(() => guardian = v)),
        _check('I consent to saving learning results on this device', consentData, (v) => setState(() => consentData = v)),
        _check('I consent to voice recording for reading-aloud activities (audio is analysed on this phone and not stored)', voice, (v) => setState(() => voice = v)),
      ]);

  Widget _stepBackground() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('About learning', style: ts(21)),
        _label('Language spoken at home'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final l in ['Hindi', 'English', 'Kannada', 'Marathi', 'Other']) _chip(l, bg.homeLanguage == l, () => setState(() => bg.homeLanguage = l))]),
        _label('Medium of instruction at school'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final l in ['English', 'Hindi', 'Kannada', 'Marathi', 'Other']) _chip(l, bg.schoolMedium == l, () => setState(() => bg.schoolMedium = l))]),
        _label('Years in school so far'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final y in [0, 1, 2, 3, 4, 5]) _chip(y == 5 ? '5+' : '$y', bg.yearsInSchool == y, () => setState(() => bg.yearsInSchool = y))]),
        const SizedBox(height: 8),
        _check('Vision has been checked', bg.visionChecked, (v) => setState(() => bg.visionChecked = v)),
        _check('Hearing has been checked', bg.hearingChecked, (v) => setState(() => bg.hearingChecked = v)),
        _check('Started speaking later than other children', bg.speechDelay, (v) => setState(() => bg.speechDelay = v)),
        _check('A family member has had difficulty with reading', bg.familyHistory, (v) => setState(() => bg.familyHistory = v)),
      ]);

  Widget _step3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How it works', style: ts(21)),
        const SizedBox(height: 10),
        _bullet('🌉', 'First adventure: a story game with a literacy screening (about 15 minutes) in the language you chose — sounds, letters, reading aloud, spelling and understanding. The phone listens and scores automatically.'),
        _bullet('🗺️', 'Personal map: each skill gets its own game and its own difficulty.'),
        _bullet('⏱️', 'Daily play: about 10 minutes, chosen from your child’s profile.'),
        _bullet('📈', 'Weekly check-in: fresh questions show real progress and plan the next week.'),
      ]);

  Widget _bullet(String e, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: ts(16, w: FontWeight.w600, h: 1.3))),
        ]),
      );

  Widget _check(String t, bool v, ValueChanged<bool> f) => InkWell(
        onTap: () => f(!v),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: v ? C.green : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: v ? C.green : C.inkSoft, width: 2.5)),
              child: v ? const Icon(Icons.check_rounded, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(t, style: ts(16, w: FontWeight.w600))),
          ]),
        ),
      );
}

class _Progress extends StatelessWidget {
  final int step;
  const _Progress({required this.step});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < 4; i++) ...[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: i <= step ? C.purple : const Color(0xFFE6E2FA), border: Border.all(color: i == step ? C.gold : Colors.transparent, width: 3)),
          child: i < step ? const Icon(Icons.check_rounded, color: Colors.white) : Text('${i + 1}', style: ts(18, color: i <= step ? Colors.white : C.inkSoft)),
        ),
        if (i < 3) Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 5, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: i < step ? C.purple : const Color(0xFFE6E2FA), borderRadius: BorderRadius.circular(3)))),
      ],
    ]);
  }
}
