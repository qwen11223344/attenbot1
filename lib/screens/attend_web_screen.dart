import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import '../models/settings.dart';
import '../services/prefs_service.dart';

class AttendWebScreen extends StatefulWidget {
  final String mode;
  final Settings settings;
  const AttendWebScreen({super.key, required this.mode, required this.settings});
  @override
  State<AttendWebScreen> createState() => _AttendWebScreenState();
}

class _AttendWebScreenState extends State<AttendWebScreen> {
  late final WebViewController _wvc;
  String _status = 'Loading...';
  bool _done = false;
  int _pageLoads = 0;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 11; Mobile) '
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36')
      ..setOnPlatformPermissionRequest((req) => req.grant())
      ..addJavaScriptChannel('Bridge', onMessageReceived: (m) => _onMsg(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          if (_done) return;
          _pageLoads++;
          _setStatus('Page loaded...');
          // Override confirm/alert so no popup blocks us
          await _wvc.runJavaScript(
            "window.confirm=function(){return true;};"
            "window.alert=function(){};"
          );
          await Future.delayed(const Duration(milliseconds: 2500));
          if (_done) return;
          if (_pageLoads == 1) {
            await _fillLogin();
          } else {
            await _clickAttendBtn();
          }
        },
      ));

    _wvc.loadRequest(Uri.parse(widget.settings.url));
    _setStatus('Opening ${widget.settings.url}...');
  }

  Future<void> _fillLogin() async {
    _setStatus('Filling login form...');
    final em = _esc(widget.settings.email);
    final pw = _esc(widget.settings.password);
    await _wvc.runJavaScript('''
(function(){
  window.confirm=function(){return true;};
  window.alert=function(){};
  var ef=document.querySelector('input[type=email]')
      ||document.querySelector('input[name*=email i]')
      ||document.querySelector('input[id*=email i]')
      ||document.querySelector('input[placeholder*=email i]')
      ||document.querySelector('input[placeholder*=user i]');
  var pf=document.querySelector('input[type=password]');
  var rs=document.querySelector('select');
  function fill(el,val){
    if(!el)return;
    el.focus();
    try{var nv=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value');
      if(nv)nv.set.call(el,val);else el.value=val;}catch(e){el.value=val;}
    el.dispatchEvent(new Event('input',{bubbles:true}));
    el.dispatchEvent(new Event('change',{bubbles:true}));
  }
  fill(ef,'$em');
  fill(pf,'$pw');
  if(rs){
    for(var i=0;i<rs.options.length;i++){
      if((rs.options[i].text+rs.options[i].value).toLowerCase().includes('staff')){
        rs.selectedIndex=i;
        rs.dispatchEvent(new Event('change',{bubbles:true}));
        break;
      }
    }
  }
  Bridge.postMessage('filled');
})();
''');
    await Future.delayed(const Duration(milliseconds: 900));
    await _clickLoginBtn();
  }

  Future<void> _clickLoginBtn() async {
    _setStatus('Logging in...');
    await _wvc.runJavaScript('''
(function(){
  window.confirm=function(){return true;};
  var btns=document.querySelectorAll('button,input[type=submit],[role=button],.btn');
  for(var i=0;i<btns.length;i++){
    var t=(btns[i].textContent||btns[i].value||'').toLowerCase().trim();
    if(t.includes('login')||t.includes('sign in')||t.includes('submit')){
      btns[i].click();
      Bridge.postMessage('login-clicked');
      return;
    }
  }
  var f=document.querySelector('form');
  if(f){f.submit();Bridge.postMessage('form-submitted');return;}
  Bridge.postMessage('login-not-found');
})();
''');
  }

  Future<void> _clickAttendBtn() async {
    if (_done) return;
    final kw1 = widget.mode=='checkin' ? 'check in'  : 'check out';
    final kw2 = widget.mode=='checkin' ? 'checkin'   : 'checkout';
    final kw3 = widget.mode=='checkin' ? 'check-in'  : 'check-out';
    _setStatus('Finding ${widget.mode=="checkin"?"CHECK IN":"CHECK OUT"} button...');

    await _wvc.runJavaScript("window.confirm=function(){return true;};window.alert=function(){};");
    await Future.delayed(const Duration(milliseconds: 400));

    await _wvc.runJavaScript('''
(function(){
  window.confirm=function(){return true;};
  window.alert=function(){};
  var els=document.querySelectorAll('button,a,input[type=button],input[type=submit],[role=button],[class*=check],[id*=check]');
  for(var i=0;i<els.length;i++){
    var t=(els[i].textContent||els[i].value||els[i].innerText||'').replace(/\\s+/g,' ').trim().toLowerCase();
    if(t==='$kw1'||t==='$kw2'||t==='$kw3'||t.includes('$kw1')||t.includes('$kw2')){
      els[i].scrollIntoView({block:'center'});
      window.confirm=function(){return true;};
      els[i].click();
      Bridge.postMessage('DONE:'+els[i].textContent.trim());
      return;
    }
  }
  var all=document.querySelectorAll('*');
  for(var j=0;j<all.length;j++){
    var tag=all[j].tagName.toLowerCase();
    if(tag!=='button'&&tag!=='a'&&!all[j].onclick)continue;
    var tx=(all[j].textContent||'').replace(/\\s+/g,' ').trim().toLowerCase();
    if(tx.includes('$kw1')||tx.includes('$kw2')){
      window.confirm=function(){return true;};
      all[j].click();
      Bridge.postMessage('DONE:'+all[j].textContent.trim());
      return;
    }
  }
  Bridge.postMessage('NOT_FOUND');
})();
''');
    await Future.delayed(const Duration(seconds: 3));
    if (!_done) {
      _setStatus('Retrying...');
      await _wvc.runJavaScript('''
(function(){
  window.confirm=function(){return true;};
  var kw='${widget.mode=="checkin"?"check in":"check out"}';
  var all=document.querySelectorAll('button,a,[role=button],[class*=btn]');
  for(var i=0;i<all.length;i++){
    var t=(all[i].textContent||'').trim().toLowerCase();
    if(t.includes(kw)){
      window.confirm=function(){return true;};
      all[i].click();
      Bridge.postMessage('DONE-RETRY:'+t);
      return;
    }
  }
  Bridge.postMessage('FINAL_NOT_FOUND');
})();
''');
    }
  }

  void _onMsg(String msg) async {
    debugPrint('Bridge: $msg');
    if (msg.startsWith('DONE')) {
      if (_done) return;
      _done = true;
      await Future.delayed(const Duration(milliseconds: 1500));
      final now   = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      final label = widget.mode=='checkin' ? 'Check In' : 'Check Out';
      await PrefsService.addRecord('$now ($label)');
      if (!mounted) return;
      setState(() => _status = '$label done! $now');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop(true);
    } else if (msg=='FINAL_NOT_FOUND') {
      _setStatus('Button not found — please tap manually');
    }
  }

  void _setStatus(String s) { if (mounted) setState(() => _status = s); }

  String _esc(String s) => s
      .replaceAll('\\','\\\\').replaceAll("'","\\'")
      .replaceAll('\n','\\n').replaceAll('\r','');

  @override
  Widget build(BuildContext context) {
    final isIn  = widget.mode=='checkin';
    final color = isIn ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    final label = isIn ? '✅  CHECK IN' : '🚪  CHECK OUT';
    return Scaffold(
      body: Column(children: [
        Container(
          color: color,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16,10,8,12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 8),
              _done
                ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28)
                : const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
            ]),
          )),
        ),
        LinearProgressIndicator(
          value: _done ? 1.0 : null, minHeight: 3,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        Expanded(child: WebViewWidget(controller: _wvc)),
      ]),
    );
  }
}
