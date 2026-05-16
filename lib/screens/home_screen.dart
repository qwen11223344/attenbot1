import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/settings.dart';
import '../services/prefs_service.dart';
import 'attend_web_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Settings s = Settings();
  final urlCtrl   = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();
  bool passVisible = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    s = await PrefsService.load();
    urlCtrl.text   = s.url;
    emailCtrl.text = s.email;
    passCtrl.text  = s.password;
    setState(() {});
  }

  Future<void> _save() async {
    s.url = urlCtrl.text.trim();
    s.email = emailCtrl.text.trim();
    s.password = passCtrl.text;
    await PrefsService.save(s);
    _snack('Settings saved ✓', const Color(0xFF2E7D32));
    setState(() {});
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: c, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _run(String mode) async {
    s.url = urlCtrl.text.trim();
    s.email = emailCtrl.text.trim();
    s.password = passCtrl.text;
    if (s.email.isEmpty || s.password.isEmpty) {
      _snack('Please enter Email and Password first', Colors.orange);
      return;
    }
    await PrefsService.save(s);
    if (!mounted) return;
    final ok = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => AttendWebScreen(mode: mode, settings: s)));
    if (ok == true) _load();
  }

  void _toggleBot(bool on) async {
    if (on && (s.email.isEmpty || s.password.isEmpty)) {
      _snack('Please enter Email and Password first', Colors.orange);
      return;
    }
    setState(() => s.botEnabled = on);
    s.url = urlCtrl.text.trim();
    s.email = emailCtrl.text.trim();
    s.password = passCtrl.text;
    await PrefsService.save(s);
    _snack(on ? 'Auto Bot ON ✓' : 'Auto Bot OFF',
        on ? const Color(0xFF2E7D32) : Colors.grey);
  }

  void _pickTime(bool isIn) {
    int h  = isIn ? s.inHour  : s.outHour;
    int m  = isIn ? s.inMin   : s.outMin;
    bool p = isIn ? s.inPm    : s.outPm;
    showDialog(context: context, builder: (_) => _TimePicker(
      title: isIn ? 'CHECK IN Time' : 'CHECK OUT Time',
      color: isIn ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
      hour: h, min: m, isPm: p,
      onSave: (nh, nm, np) async {
        setState(() {
          if (isIn) { s.inHour=nh;  s.inMin=nm;  s.inPm=np;  }
          else      { s.outHour=nh; s.outMin=nm; s.outPm=np; }
        });
        await PrefsService.save(s);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _secLabel('WEBSITE URL'),
            _card(_fieldRow(Icons.language_rounded, TextField(
              controller: urlCtrl, keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 14),
              decoration: _deco('https://lms.gims.tech/'),
            ))),
            _secLabel('LOGIN DETAILS'),
            _card(Column(children: [
              _fieldRow(Icons.email_outlined, TextField(
                controller: emailCtrl, keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: _deco('Email address'),
              )),
              const Divider(height: 1),
              _fieldRow(Icons.lock_outline_rounded, TextField(
                controller: passCtrl, obscureText: !passVisible,
                style: const TextStyle(fontSize: 14),
                decoration: _deco('Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(passVisible ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: Colors.grey),
                    onPressed: () => setState(() => passVisible = !passVisible),
                  ),
                ),
              )),
              const SizedBox(height: 6),
              Row(children: const [
                Icon(Icons.shield_outlined, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text('Saved only on your device', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ]),
            ])),
            _secLabel('AUTO TIMING (12-HOUR)'),
            _card(Column(children: [
              _timeRow('CHECK IN',  s.inTime,  const Color(0xFF1B5E20), Icons.login_rounded,  () => _pickTime(true)),
              const SizedBox(height: 8),
              _timeRow('CHECK OUT', s.outTime, const Color(0xFFB71C1C), Icons.logout_rounded, () => _pickTime(false)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Bot will auto login, allow location, select Staff role, '
                    'and press CHECK IN / OUT at set times. No action needed.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                  )),
                ]),
              ),
            ])),
            _secLabel('AUTO BOT'),
            _card(Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Enable Auto Attendance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(s.botEnabled
                  ? 'Active — runs at ${s.inTime} and ${s.outTime}'
                  : 'Off — tap to enable',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ])),
              CupertinoSwitch(value: s.botEnabled, onChanged: _toggleBot,
                  activeColor: const Color(0xFF4CAF50)),
            ])),
            const SizedBox(height: 4),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            const SizedBox(height: 20),
            _secLabel('MANUAL ATTENDANCE'),
            Row(children: [
              Expanded(child: _bigBtn('✅  CHECK IN',  const Color(0xFF1B5E20), () => _run('checkin'))),
              const SizedBox(width: 10),
              Expanded(child: _bigBtn('🚪  CHECK OUT', const Color(0xFFB71C1C), () => _run('checkout'))),
            ]),
            const SizedBox(height: 20),
            _secLabel('ATTENDANCE HISTORY'),
            _historyCard(),
            const SizedBox(height: 30),
          ])),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20,16,20,24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30),
            ),
            child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AttendBot',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(s.botEnabled ? '● Auto ON' : '○ Auto OFF',
                style: TextStyle(
                  color: s.botEnabled ? const Color(0xFF69F0AE) : Colors.white54,
                  fontSize: 12)),
          ])),
          CupertinoSwitch(value: s.botEnabled, onChanged: _toggleBot,
              activeColor: const Color(0xFF4CAF50)),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _pill('CHECK IN',  s.inTime,  const Color(0xFF2E7D32), true),
          const SizedBox(width: 10),
          _pill('CHECK OUT', s.outTime, const Color(0xFFB71C1C), false),
        ]),
        const SizedBox(height: 8),
        Text('Last: ${s.lastRecord}',
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    )),
  );

  Widget _pill(String lbl, String time, Color c, bool isIn) =>
    Expanded(child: GestureDetector(
      onTap: () => _pickTime(isIn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.withOpacity(0.85), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lbl, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(children: [
            Text(time, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: Colors.white54),
          ]),
        ]),
      ),
    ));

  Widget _secLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(t, style: const TextStyle(
        color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
  );

  Widget _card(Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  Widget _fieldRow(IconData icon, Widget child) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 4), child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 12),
        Expanded(child: child),
      ]));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint, border: InputBorder.none,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
  );

  Widget _timeRow(String lbl, String time, Color c, IconData icon, VoidCallback onTap) =>
    InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(width: 10),
        Text(lbl, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)),
        const Spacer(),
        Text(time, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right, color: c.withOpacity(0.4)),
      ]),
    ));

  Widget _bigBtn(String lbl, Color c, VoidCallback fn) =>
    SizedBox(height: 56, child: ElevatedButton(
      onPressed: fn,
      style: ElevatedButton.styleFrom(
        backgroundColor: c, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Text(lbl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    ));

  Widget _historyCard() {
    if (s.history.isEmpty) return _card(const Center(
      child: Padding(padding: EdgeInsets.all(8),
        child: Text('No records yet', style: TextStyle(color: Colors.grey)))));
    return _card(Column(children: s.history.reversed.take(10).toList().asMap().entries.map((e) {
      final isIn = e.value.contains('Check In');
      return Column(children: [
        if (e.key > 0) const Divider(height: 1),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child:
          Row(children: [
            Icon(isIn ? Icons.login : Icons.logout, size: 16,
                color: isIn ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C)),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12))),
          ])),
      ]);
    }).toList()));
  }
}

class _TimePicker extends StatefulWidget {
  final String title; final Color color;
  final int hour, min; final bool isPm;
  final Future<void> Function(int,int,bool) onSave;
  const _TimePicker({required this.title, required this.color,
    required this.hour, required this.min, required this.isPm, required this.onSave});
  @override State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> {
  late int h, m; late bool pm;
  final hrs  = [12,1,2,3,4,5,6,7,8,9,10,11];
  final mins = [0,5,10,15,20,25,30,35,40,45,50,55];
  @override void initState() { super.initState(); h=widget.hour; m=widget.min; pm=widget.isPm; }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(16,16,16,0),
      content: SizedBox(height: 150, child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wheel(hrs.map((x)=>x.toString()).toList(), hrs.indexOf(h==0?12:h), (i)=>setState(()=>h=hrs[i])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.color))),
          _wheel(mins.map((x)=>x.toString().padLeft(2,'0')).toList(), mins.indexOf(m), (i)=>setState(()=>m=mins[i])),
          const SizedBox(width: 16),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _amPm('AM', !pm),
            const SizedBox(height: 8),
            _amPm('PM', pm),
          ]),
        ],
      )),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () async { await widget.onSave(h,m,pm); if(context.mounted)Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Set Time'),
        ),
      ],
    );
  }

  Widget _wheel(List<String> items, int init, ValueChanged<int> onChange) =>
    SizedBox(width: 52, child: ListWheelScrollView.useDelegate(
      controller: FixedExtentScrollController(initialItem: init),
      itemExtent: 44, perspective: 0.003, diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChange,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (_,i) => Center(child: Text(items[i], style: TextStyle(
          fontSize: i==init?22:15,
          fontWeight: i==init?FontWeight.bold:FontWeight.normal,
          color: i==init?widget.color:Colors.grey))),
      ),
    ));

  Widget _amPm(String lbl, bool selected) => GestureDetector(
    onTap: () => setState(() => pm=lbl=='PM'),
    child: Container(
      width: 52, padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? widget.color : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? widget.color : Colors.grey.shade300),
      ),
      child: Text(lbl, textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: selected?Colors.white:Colors.grey)),
    ),
  );
}
