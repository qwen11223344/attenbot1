class Settings {
  String url;
  String email;
  String password;
  int inHour;
  int inMin;
  bool inPm;
  int outHour;
  int outMin;
  bool outPm;
  bool botEnabled;
  String lastRecord;
  List<String> history;

  Settings({
    this.url = 'https://lms.gims.tech/',
    this.email = '',
    this.password = '',
    this.inHour = 8, this.inMin = 30, this.inPm = false,
    this.outHour = 5, this.outMin = 0,  this.outPm = true,
    this.botEnabled = false,
    this.lastRecord = 'None',
    List<String>? history,
  }) : history = history ?? [];

  String get inTime  => '${inHour == 0 ? 12 : inHour}:${inMin.toString().padLeft(2,'0')} ${inPm  ? "PM":"AM"}';
  String get outTime => '${outHour== 0 ? 12 : outHour}:${outMin.toString().padLeft(2,'0')} ${outPm ? "PM":"AM"}';
  int get inHour24  => !inPm  ? (inHour ==12?0:inHour)  : (inHour ==12?12:inHour +12);
  int get outHour24 => !outPm ? (outHour==12?0:outHour) : (outHour==12?12:outHour+12);
}
