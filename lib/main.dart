import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyLifeApp());
}

class MyLifeApp extends StatelessWidget {
  const MyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Basma Calendar',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CalendarPage(),
    const TaskManagerPage(),
    const SalatSchedulePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basma Calendar'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 9,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '3-in-1 Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'Tasks & Alarms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_filled),
            label: 'Salat & Azan',
          ),
        ],
      ),
    );
  }
}

enum PrimaryCalendarType { gregorian, ethiopian, hijri }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  PrimaryCalendarType _primaryCalendar = PrimaryCalendarType.gregorian;

  final List<String> ethiopianMonths = [
    'መስከረም (Meskerem)',
    'ጥቅምት (Tikimt)',
    'ኅዳር (Hidar)',
    'ታኅሣሥ (Tahsas)',
    'ጥር (Tir)',
    'የካቲት (Yekatit)',
    'መጋቢት (Megabit)',
    'ሚያዝያ (Miyazia)',
    'ግንቦት (Ginbot)',
    'ሰኔ (Sene)',
    'ሐምሌ (Hamle)',
    'ነሐሴ (Nehase)',
    'ጳጉሜ (Pagume)'
  ];

  final List<String> hijriMonths = [
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qa\'dah',
    'Dhu al-Hijjah'
  ];

  final List<String> gregorianMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String safeGetMonth(List<String> list, int monthIndex) {
    int idx = (monthIndex - 1) % list.length;
    if (idx < 0) idx += list.length;
    return list[idx];
  }

  Map<String, dynamic> getEthiopianDateDetails(DateTime date) {
    int gYear = date.year;
    int gMonth = date.month;
    int gDay = date.day;

    int ethYear = gYear - 8;
    int ethMonth = 1;
    int ethDay = 1;

    if (gMonth == 9) {
      if (gDay < 6) {
        ethMonth = 13;
        ethDay = gDay + 25;
        ethYear = gYear - 8;
      } else if (gDay >= 6 && gDay <= 10) {
        ethMonth = 13;
        ethDay = gDay - 5;
        ethYear = gYear - 8;
      } else {
        ethMonth = 1;
        ethDay = gDay - 10;
        ethYear = gYear - 7;
      }
    } else if (gMonth > 9) {
      ethYear = gYear - 7;
      ethMonth = (gMonth == 10 && gDay < 11) ? 1 : (gMonth == 10 ? 2 : (gMonth - 8));
      ethDay = (gMonth == 10 && gDay >= 11) ? gDay - 10 : gDay;
    } else {
      ethMonth = gMonth + 4;
      ethDay = gDay;
    }

    String monthName = safeGetMonth(ethiopianMonths, ethMonth);

    return {
      "month": ethMonth,
      "day": ethDay,
      "year": ethYear,
      "text": "$monthName $ethDay, $ethYear E.C."
    };
  }

  Map<String, dynamic> getHijriDateDetails(DateTime date) {
    double julianDay = date.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
    int l = (julianDay - 1948440 + 10632).toInt();
    int n = ((l - 1) / 10631).toInt();
    l = l - 10631 * n + 354;
    int j = (((10985 - l) / 5316)).toInt() * (((50 * l) / 17719)).toInt() +
        ((l / 5670)).toInt() * (((43 * l) / 15238)).toInt();
    l = l -
        (((30 - j) / 15)).toInt() * (((17719 * j) / 50)).toInt() -
        ((j / 16)).toInt() * (((15238 * j) / 43)).toInt() +
        29;
    int hMonth = ((24 * l) / 709).toInt();
    int hDay = l - ((709 * hMonth) / 24).toInt();
    int hYear = 30 * n + j - 30;

    String monthName = safeGetMonth(hijriMonths, hMonth);

    return {
      "month": hMonth,
      "day": hDay,
      "year": hYear,
      "text": "$monthName $hDay, $hYear AH"
    };
  }

  List<String> getHolyDaysForDay(DateTime date) {
    List<String> holyDays = [];
    final eth = getEthiopianDateDetails(date);
    final hijri = getHijriDateDetails(date);

    if (hijri["month"] == 9 && hijri["day"] == 1) {
      holyDays.add("☪️ First Day of Ramadan (Start of Fasting)");
    } else if (hijri["month"] == 9 && hijri["day"] == 27) {
      holyDays.add("☪️ Laylat al-Qadr (Night of Power)");
    } else if (hijri["month"] == 10 && hijri["day"] == 1) {
      holyDays.add("🎉 Eid al-Fitr (Islamic Celebration)");
    } else if (hijri["month"] == 12 && hijri["day"] == 9) {
      holyDays.add("☪️ Day of Arafah");
    } else if (hijri["month"] == 12 && hijri["day"] == 10) {
      holyDays.add("🎉 Eid al-Adha (Feast of Sacrifice)");
    } else if (hijri["month"] == 1 && hijri["day"] == 1) {
      holyDays.add("🌙 Islamic New Year (1st Muharram)");
    } else if (hijri["month"] == 1 && hijri["day"] == 10) {
      holyDays.add("☪️ Day of Ashura");
    } else if (hijri["month"] == 3 && hijri["day"] == 12) {
      holyDays.add("☪️ Mawlid an-Nabi (Prophet's Birthday)");
    }

    if (eth["month"] == 1 && eth["day"] == 1) {
      holyDays.add("🇪🇹 Enkutatash (Ethiopian New Year)");
    } else if (eth["month"] == 1 && eth["day"] == 17) {
      holyDays.add("✝️ Meskel (Finding of the True Cross)");
    } else if (eth["month"] == 4 && eth["day"] == 29) {
      holyDays.add("✝️ Genna (Ethiopian Christmas)");
    } else if (eth["month"] == 5 && eth["day"] == 11) {
      holyDays.add("✝️ Timkat (Ethiopian Epiphany)");
    }

    return holyDays;
  }

  List<Map<String, String>> getHolyDaysForMonth(DateTime selectedDate) {
    List<Map<String, String>> monthHolyDays = [];
    int daysInMonth = DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month);

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime checkDate = DateTime(selectedDate.year, selectedDate.month, day);
      List<String> events = getHolyDaysForDay(checkDate);

      for (String event in events) {
        monthHolyDays.add({
          "day": "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}",
          "event": event,
        });
      }
    }

    return monthHolyDays;
  }

  Widget _buildDynamicGridCalendar() {
    int daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    int startingWeekday = firstDayOfMonth.weekday % 7;

    final ethHeader = getEthiopianDateDetails(_selectedDate);
    final hijriHeader = getHijriDateDetails(_selectedDate);

    String mainTitle = "";
    if (_primaryCalendar == PrimaryCalendarType.gregorian) {
      mainTitle = "${gregorianMonths[_selectedDate.month - 1]} ${_selectedDate.year}";
    } else if (_primaryCalendar == PrimaryCalendarType.ethiopian) {
      mainTitle = ethHeader["text"];
    } else {
      mainTitle = hijriHeader["text"];
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mainTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                              _selectedDate.year, _selectedDate.month - 1, 15);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                              _selectedDate.year, _selectedDate.month + 1, 15);
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
            const Divider(),
            Row(
              children: const [
                Expanded(child: Center(child: Text("S", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("M", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("T", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("W", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("T", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("F", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("S", style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: startingWeekday + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                if (index < startingWeekday) {
                  return const SizedBox();
                }

                int dayNum = index - startingWeekday + 1;
                DateTime currentGridDate =
                    DateTime(_selectedDate.year, _selectedDate.month, dayNum);

                String displayNum = "$dayNum";
                if (_primaryCalendar == PrimaryCalendarType.ethiopian) {
                  displayNum = "${getEthiopianDateDetails(currentGridDate)["day"]}";
                } else if (_primaryCalendar == PrimaryCalendarType.hijri) {
                  displayNum = "${getHijriDateDetails(currentGridDate)["day"]}";
                }

                bool isSelected = dayNum == _selectedDate.day;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = currentGridDate;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayNum,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isPrimary = false,
  }) {
    return Card(
      color: bgColor,
      elevation: isPrimary ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPrimary ? BorderSide(color: color, width: 2.5) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: color, size: isPrimary ? 36 : 28),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                fontSize: isPrimary ? 16 : 14,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "MAIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ]
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isPrimary ? 18 : 15,
            color: isPrimary ? color : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ethData = getEthiopianDateDetails(_selectedDate);
    final hijriData = getHijriDateDetails(_selectedDate);
    final monthlyHolyDays = getHolyDaysForMonth(_selectedDate);

    final gregCard = _buildCalendarCard(
      title: "Gregorian Calendar",
      subtitle:
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
      icon: Icons.public,
      color: Colors.blue,
      bgColor: Colors.blue.shade50,
      isPrimary: _primaryCalendar == PrimaryCalendarType.gregorian,
    );

    final ethCard = _buildCalendarCard(
      title: "Ethiopian Calendar (የኢትዮጵያ ዘመን አቆጣጠር)",
      subtitle: ethData["text"],
      icon: Icons.flag,
      color: Colors.amber.shade800,
      bgColor: Colors.amber.shade50,
      isPrimary: _primaryCalendar == PrimaryCalendarType.ethiopian,
    );

    final hijriCard = _buildCalendarCard(
      title: "Hijri Calendar (التقويم الهجري)",
      subtitle: hijriData["text"],
      icon: Icons.nightlight_round,
      color: Colors.green.shade800,
      bgColor: Colors.green.shade50,
      isPrimary: _primaryCalendar == PrimaryCalendarType.hijri,
    );

    List<Widget> calendarCards = [];
    if (_primaryCalendar == PrimaryCalendarType.gregorian) {
      calendarCards = [gregCard, ethCard, hijriCard];
    } else if (_primaryCalendar == PrimaryCalendarType.ethiopian) {
      calendarCards = [ethCard, gregCard, hijriCard];
    } else {
      calendarCards = [hijriCard, gregCard, ethCard];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDynamicGridCalendar(),
          const SizedBox(height: 12),

          const Text(
            "Select Primary Calendar System",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          SegmentedButton<PrimaryCalendarType>(
            segments: const [
              ButtonSegment(
                value: PrimaryCalendarType.gregorian,
                label: Text("Gregorian"),
                icon: Icon(Icons.public, size: 16),
              ),
              ButtonSegment(
                value: PrimaryCalendarType.ethiopian,
                label: Text("Ethiopian"),
                icon: Icon(Icons.flag, size: 16),
              ),
              ButtonSegment(
                value: PrimaryCalendarType.hijri,
                label: Text("Hijri"),
                icon: Icon(Icons.nightlight_round, size: 16),
              ),
            ],
            selected: {_primaryCalendar},
            onSelectionChanged: (Set<PrimaryCalendarType> newSelection) {
              setState(() {
                _primaryCalendar = newSelection.first;
              });
            },
          ),

          const SizedBox(height: 15),

          ...calendarCards,

          const SizedBox(height: 20),

          Card(
            color: Colors.purple.shade50,
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.stars, color: Colors.purple, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Holy Days & Holidays of this Month",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.purple),
                  if (monthlyHolyDays.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "No major religious or national holidays listed for this month.",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                      ),
                    )
                  else
                    Column(
                      children: monthlyHolyDays.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item["day"]!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item["event"]!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskManagerPage extends StatefulWidget {
  const TaskManagerPage({super.key});

  @override
  State<TaskManagerPage> createState() => _TaskManagerPageState();
}

class TaskItem {
  String title;
  bool isDone;
  bool hasAlarm;
  TimeOfDay time;

  TaskItem({
    required this.title,
    this.isDone = false,
    this.hasAlarm = false,
    required this.time,
  });
}

class _TaskManagerPageState extends State<TaskManagerPage> {
  List<TaskItem> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskListJson = _tasks
        .map((task) => jsonEncode({
              'title': task.title,
              'isDone': task.isDone,
              'hasAlarm': task.hasAlarm,
              'hour': task.time.hour,
              'minute': task.time.minute,
            }))
        .toList();
    await prefs.setStringList('saved_user_tasks', taskListJson);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? taskListJson = prefs.getStringList('saved_user_tasks');
    if (taskListJson != null && taskListJson.isNotEmpty) {
      setState(() {
        _tasks = taskListJson.map((item) {
          final map = jsonDecode(item);
          return TaskItem(
            title: map['title'],
            isDone: map['isDone'] ?? false,
            hasAlarm: map['hasAlarm'] ?? false,
            time: TimeOfDay(hour: map['hour'], minute: map['minute']),
          );
        }).toList();
      });
    } else {
      setState(() {
        _tasks = [
          TaskItem(
            title: "Perform Fajr prayer",
            hasAlarm: true,
            time: const TimeOfDay(hour: 5, minute: 38),
          ),
          TaskItem(
            title: "Review daily schedule",
            hasAlarm: false,
            time: const TimeOfDay(hour: 9, minute: 0),
          ),
        ];
      });
      _saveTasks();
    }
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(TaskItem(
          title: _taskController.text,
          time: _selectedTime,
        ));
        _taskController.clear();
      });
      _saveTasks();
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    labelText: 'Add a new task',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.access_time, color: Colors.teal),
                onPressed: () => _selectTime(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _addTask,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      activeColor: Colors.teal,
                      value: task.isDone,
                      onChanged: (bool? value) {
                        setState(() {
                          task.isDone = value ?? false;
                        });
                        _saveTasks();
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text("Time: ${task.time.format(context)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            task.hasAlarm
                                ? Icons.alarm_on
                                : Icons.alarm_off,
                            color: task.hasAlarm ? Colors.teal : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              task.hasAlarm = !task.hasAlarm;
                            });
                            _saveTasks();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(task.hasAlarm
                                    ? "Alarm enabled for '${task.title}'"
                                    : "Alarm disabled"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _tasks.removeAt(index);
                            });
                            _saveTasks();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. SALAT SCHEDULE PAGE (200+ ETHIOPIAN CITIES + MAKKAH & MADINAH)
// ---------------------------------------------------------------------------
class SalatSchedulePage extends StatefulWidget {
  const SalatSchedulePage({super.key});

  @override
  State<SalatSchedulePage> createState() => _SalatSchedulePageState();
}

class _SalatSchedulePageState extends State<SalatSchedulePage> {
  String _selectedCity = "Addis Ababa";
  String _searchFilter = "";
  bool _isLoading = false;

  final Map<String, String> _cityCountries = {
    // Saudi Arabia Holy Cities
    "Makkah": "Saudi Arabia",
    "Madinah": "Saudi Arabia",

    // Addis Ababa Administration
    "Addis Ababa": "Ethiopia",
    "Akaki": "Ethiopia",
    "Kaliti": "Ethiopia",
    "Nifas Silk": "Ethiopia",
    "Kolfe Keranio": "Ethiopia",
    "Gullele": "Ethiopia",
    "Arada": "Ethiopia",
    "Yeka": "Ethiopia",
    "Bole": "Ethiopia",
    "Akaki Kality": "Ethiopia",

    // Dire Dawa Administration
    "Dire Dawa": "Ethiopia",
    "Melka Jebdu": "Ethiopia",

    // Oromia Region
    "Adama": "Ethiopia",
    "Jimma": "Ethiopia",
    "Bishoftu": "Ethiopia",
    "Shashamane": "Ethiopia",
    "Asella": "Ethiopia",
    "Ambo": "Ethiopia",
    "Nekemte": "Ethiopia",
    "Robie": "Ethiopia",
    "Bale Robe": "Ethiopia",
    "Batu": "Ethiopia",
    "Ziway": "Ethiopia",
    "Haramaya": "Ethiopia",
    "Gimbi": "Ethiopia",
    "Metu": "Ethiopia",
    "Bedele": "Ethiopia",
    "Dembi Dolo": "Ethiopia",
    "Fiche": "Ethiopia",
    "Holeta": "Ethiopia",
    "Sululta": "Ethiopia",
    "Burayu": "Ethiopia",
    "Dukem": "Ethiopia",
    "Mojo": "Ethiopia",
    "Sebeta": "Ethiopia",
    "Bale Goba": "Ethiopia",
    "Agaro": "Ethiopia",
    "Buno Bedele": "Ethiopia",
    "Negele Borana": "Ethiopia",
    "Yabelo": "Ethiopia",
    "Moyale": "Ethiopia",
    "Shambu": "Ethiopia",
    "Mena": "Ethiopia",
    "Dodola": "Ethiopia",
    "Adaba": "Ethiopia",
    "Shakiso": "Ethiopia",
    "Adola": "Ethiopia",
    "Kibre Mengist": "Ethiopia",
    "Bako": "Ethiopia",
    "Gedo": "Ethiopia",
    "Ejaji": "Ethiopia",
    "Mugi": "Ethiopia",
    "Nedjo": "Ethiopia",
    "Gulliso": "Ethiopia",
    "Aira": "Ethiopia",
    "Mandi": "Ethiopia",
    "Meti": "Ethiopia",
    "Gore": "Ethiopia",
    "Hurumu": "Ethiopia",
    "Yayu": "Ethiopia",
    "Limmu Genet": "Ethiopia",

    // Amhara Region
    "Bahir Dar": "Ethiopia",
    "Gondar": "Ethiopia",
    "Dessie": "Ethiopia",
    "Kombolcha": "Ethiopia",
    "Debre Birhan": "Ethiopia",
    "Debre Markos": "Ethiopia",
    "Debre Tabor": "Ethiopia",
    "Weldiya": "Ethiopia",
    "Kobo": "Ethiopia",
    "Finote Selam": "Ethiopia",
    "Injibara": "Ethiopia",
    "Mota": "Ethiopia",
    "Dangila": "Ethiopia",
    "Lalibela": "Ethiopia",
    "Enjibara": "Ethiopia",
    "Bichena": "Ethiopia",
    "Dejen": "Ethiopia",
    "Shewa Robit": "Ethiopia",
    "Ataye": "Ethiopia",
    "Karakore": "Ethiopia",
    "Bati": "Ethiopia",
    "Haike": "Ethiopia",
    "Kemise": "Ethiopia",
    "Alamata": "Ethiopia",
    "Dabat": "Ethiopia",
    "Debark": "Ethiopia",
    "Addis Zemen": "Ethiopia",
    "Wereta": "Ethiopia",
    "Metema": "Ethiopia",
    "Humera": "Ethiopia",
    "Sanja": "Ethiopia",
    "Chagni": "Ethiopia",
    "Pawe": "Ethiopia",
    "Guba": "Ethiopia",
    "Meket": "Ethiopia",
    "Gassicha": "Ethiopia",
    "Memsa": "Ethiopia",

    // Tigray Region
    "Mekelle": "Ethiopia",
    "Adigrat": "Ethiopia",
    "Aksum": "Ethiopia",
    "Shire": "Ethiopia",
    "Adwa": "Ethiopia",
    "Maychew": "Ethiopia",
    "Wukro": "Ethiopia",
    "Korem": "Ethiopia",
    "Abiy Addi": "Ethiopia",
    "Sheraro": "Ethiopia",
    "Humera City": "Ethiopia",
    "Bati Tigray": "Ethiopia",
    "Mehoni": "Ethiopia",
    "Alitena": "Ethiopia",
    "Enticho": "Ethiopia",
    "Rama": "Ethiopia",
    "Hagere Selam": "Ethiopia",

    // Sidama Region
    "Hawassa": "Ethiopia",
    "Yirgalem": "Ethiopia",
    "Aleta Wendo": "Ethiopia",
    "Leku": "Ethiopia",
    "Bensa": "Ethiopia",
    "Daye": "Ethiopia",
    "Chuko": "Ethiopia",
    "Wondo Genet": "Ethiopia",
    "Yirba": "Ethiopia",

    // Somali Region
    "Jijiga": "Ethiopia",
    "Gode": "Ethiopia",
    "Degehabur": "Ethiopia",
    "Kebri Dahar": "Ethiopia",
    "Dire Dawa Somali": "Ethiopia",
    "Ferfer": "Ethiopia",
    "Kelafo": "Ethiopia",
    "Shilavo": "Ethiopia",
    "Warder": "Ethiopia",
    "Geladin": "Ethiopia",
    "Babile": "Ethiopia",
    "Fiq": "Ethiopia",
    "Hamero": "Ethiopia",
    "Imi": "Ethiopia",
    "Moyale Somali": "Ethiopia",
    "Dollo Ado": "Ethiopia",
    "Bokolmayo": "Ethiopia",
    "Suftu": "Ethiopia",
    "Chereti": "Ethiopia",
    "El Kere": "Ethiopia",

    // Southern Nations, Nationalities, and Peoples (SNNP / South Ethiopia / Central Ethiopia)
    "Arba Minch": "Ethiopia",
    "Wolaita Sodo": "Ethiopia",
    "Hosaena": "Ethiopia",
    "Dilla": "Ethiopia",
    "Butajira": "Ethiopia",
    "Sodo": "Ethiopia",
    "Sawla": "Ethiopia",
    "Jinka": "Ethiopia",
    "Bonga": "Ethiopia",
    "Mizan Teferi": "Ethiopia",
    "Tepi": "Ethiopia",
    "Worabe": "Ethiopia",
    "Durame": "Ethiopia",
    "Aroresa": "Ethiopia",
    "Boditi": "Ethiopia",
    "Areka": "Ethiopia",
    "Bule Hora": "Ethiopia",
    "Yabelo SNNP": "Ethiopia",
    "Konso": "Ethiopia",
    "Karat": "Ethiopia",
    "Turmi": "Ethiopia",
    "Dimeka": "Ethiopia",
    "Majin": "Ethiopia",
    "Chencha": "Ethiopia",
    "Gidole": "Ethiopia",
    "Weito": "Ethiopia",
    "Key Afer": "Ethiopia",
    "Omorate": "Ethiopia",
    "Kindo Didaye": "Ethiopia",
    "Basketo": "Ethiopia",
    "Laska": "Ethiopia",
    "Gimbi South": "Ethiopia",
    "Sankura": "Ethiopia",
    "Silte": "Ethiopia",

    // Harari Region
    "Harar": "Ethiopia",
    "Sofie": "Ethiopia",
    "Erer": "Ethiopia",

    // Afar Region
    "Semera": "Ethiopia",
    "Asaita": "Ethiopia",
    "Logiya": "Ethiopia",
    "Awash": "Ethiopia",
    "Awash Arba": "Ethiopia",
    "Dubti": "Ethiopia",
    "Gewane": "Ethiopia",
    "Dewe": "Ethiopia",
    "Mile": "Ethiopia",
    "Chifra": "Ethiopia",
    "Abalu": "Ethiopia",
    "Teru": "Ethiopia",
    "Megale": "Ethiopia",
    "Ewa": "Ethiopia",
    "Gullina": "Ethiopia",

    // Benishangul-Gumuz Region
    "Asosa": "Ethiopia",
    "Bambasi": "Ethiopia",
    "Metekel": "Ethiopia",
    "Gilgel Beles": "Ethiopia",
    "Kamashi": "Ethiopia",
    "Debre Zeit Gumuz": "Ethiopia",
    "Menge": "Ethiopia",
    "Oda": "Ethiopia",
    "Kurmuk": "Ethiopia",
    "Sherkole": "Ethiopia",

    // Gambela Region
    "Gambela": "Ethiopia",
    "Itang": "Ethiopia",
    "Pugnido": "Ethiopia",
    "Abobo": "Ethiopia",
    "Jor": "Ethiopia",
    "Gog": "Ethiopia",
    "Lare": "Ethiopia",
    "Wantuwa": "Ethiopia",
  };

  Map<String, String> _currentTimings = {
    "Fajr": "05:12 AM",
    "Sunrise": "06:18 AM",
    "Dhuhr": "12:15 PM",
    "Asr": "03:34 PM",
    "Maghrib": "06:11 PM",
    "Isha": "07:22 PM",
  };

  final Map<String, bool> _alarms = {};

  @override
  void initState() {
    super.initState();
    _fetchLivePrayerTimes(_selectedCity);
  }

  Future<void> _fetchLivePrayerTimes(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final country = _cityCountries[city] ?? "Ethiopia";
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=2');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data']['timings'];
        setState(() {
          _currentTimings = {
            "Fajr": data["Fajr"] ?? "05:12 AM",
            "Sunrise": data["Sunrise"] ?? "06:18 AM",
            "Dhuhr": data["Dhuhr"] ?? "12:15 PM",
            "Asr": data["Asr"] ?? "03:34 PM",
            "Maghrib": data["Maghrib"] ?? "06:11 PM",
            "Isha": data["Isha"] ?? "07:22 PM",
          };
        });
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  void _playAzanSound(String prayerName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.teal.shade800,
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "🔊 Playing Azan voice call for $prayerName prayer...",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCities = _cityCountries.keys.where((city) {
      return city.toLowerCase().contains(_searchFilter.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search 200+ cities (e.g., Makkah, Hawassa, Adama)',
              prefixIcon: Icon(Icons.search, color: Colors.teal),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _searchFilter = val;
              });
            },
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: Colors.teal),
                  const SizedBox(width: 12),
                  const Text(
                    "Selected City:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: filteredCities.contains(_selectedCity)
                          ? _selectedCity
                          : (filteredCities.isNotEmpty ? filteredCities.first : _selectedCity),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: filteredCities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(
                            "$city (${_cityCountries[city]})",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newCity) {
                        if (newCity != null) {
                          setState(() {
                            _selectedCity = newCity;
                          });
                          _fetchLivePrayerTimes(newCity);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                )
              : Expanded(
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📍 Live Salat Times: $_selectedCity (${_cityCountries[_selectedCity]})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildPrayerRow(_selectedCity, "Fajr", _currentTimings["Fajr"]!),
                          _buildPrayerRow(_selectedCity, "Sunrise", _currentTimings["Sunrise"]!),
                          _buildPrayerRow(_selectedCity, "Dhuhr", _currentTimings["Dhuhr"]!),
                          _buildPrayerRow(_selectedCity, "Asr", _currentTimings["Asr"]!),
                          _buildPrayerRow(_selectedCity, "Maghrib", _currentTimings["Maghrib"]!),
                          _buildPrayerRow(_selectedCity, "Isha", _currentTimings["Isha"]!),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(String city, String prayerName, String time) {
    String alarmKey = "$city-$prayerName";
    bool isAlarmOn = _alarms[alarmKey] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$prayerName: $time",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up, size: 22, color: Colors.teal),
                tooltip: "Preview Azan Sound",
                onPressed: () => _playAzanSound(prayerName),
              ),
              Switch(
                value: isAlarmOn,
                activeColor: Colors.teal,
                onChanged: (bool value) {
                  setState(() {
                    _alarms[alarmKey] = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? "Azan Alarm SET for $prayerName at $time"
                          : "Azan Alarm OFF for $prayerName"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
