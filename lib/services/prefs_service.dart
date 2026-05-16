import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class PrefsService {
  static Future<Settings> load() async {
    final p = await SharedPreferences.getInstance();
    final h = p.getString('history') ?? '';
    return Settings(
      url:        p.getString('url')       ?? 'https://lms.gims.tech/',
      email:      p.getString('email')     ?? '',
      password:   p.getString('password')  ?? '',
      inHour:     p.getInt('inHour')       ?? 8,
      inMin:      p.getInt('inMin')        ?? 30,
      inPm:       p.getBool('inPm')        ?? false,
      outHour:    p.getInt('outHour')      ?? 5,
      outMin:     p.getInt('outMin')       ?? 0,
      outPm:      p.getBool('outPm')       ?? true,
      botEnabled: p.getBool('botEnabled')  ?? false,
      lastRecord: p.getString('lastRecord') ?? 'None',
      history:    h.isEmpty ? [] : h.split('|'),
    );
  }

  static Future<void> save(Settings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('url',      s.url);
    await p.setString('email',    s.email);
    await p.setString('password', s.password);
    await p.setInt('inHour',  s.inHour);
    await p.setInt('inMin',   s.inMin);
    await p.setBool('inPm',   s.inPm);
    await p.setInt('outHour', s.outHour);
    await p.setInt('outMin',  s.outMin);
    await p.setBool('outPm',  s.outPm);
    await p.setBool('botEnabled', s.botEnabled);
  }

  static Future<void> addRecord(String entry) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lastRecord', entry);
    String h = p.getString('history') ?? '';
    h = h.isEmpty ? entry : '$h|$entry';
    await p.setString('history', h);
  }
}
