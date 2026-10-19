import 'package:flutter/material.dart';

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

// ---------------------------------------------------------------------------
// 1. TRI-CALENDAR PAGE WITH FULLY DYNAMIC DATES GRID
// ---------------------------------------------------------------------------
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime(2026, 10, 19);
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
      mainTitle = "October 2026";
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

// ---------------------------------------------------------------------------
// 2. TASK MANAGER PAGE
// ---------------------------------------------------------------------------
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
  final List<TaskItem> _tasks = [
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

  final TextEditingController _taskController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(TaskItem(
          title: _taskController.text,
          time: _selectedTime,
        ));
        _taskController.clear();
      });
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
// 3. SALAT SCHEDULE PAGE
// ---------------------------------------------------------------------------
class SalatSchedulePage extends StatefulWidget {
  const SalatSchedulePage({super.key});

  @override
  State<SalatSchedulePage> createState() => _SalatSchedulePageState();
}

class _SalatSchedulePageState extends State<SalatSchedulePage> {
  late List<Map<String, dynamic>> _yearPrayerTimes;
  String _searchQuery = "";

  final Map<String, bool> _alarms = {};

  @override
  void initState() {
    super.initState();
    _yearPrayerTimes = _generateFullYearSchedule();
  }

  List<Map<String, dynamic>> _generateFullYearSchedule() {
    List<Map<String, dynamic>> list = [];
    DateTime startDate = DateTime(2026, 1, 1);

    for (int i = 0; i < 365; i++) {
      DateTime currentDate = startDate.add(Duration(days: i));
      String dateStr =
          "${_getMonthName(currentDate.month)} ${currentDate.day}, 2026";

      list.add({
        "date": currentDate,
        "dateLabel": dateStr,
        "Fajr": "05:${(38 - (i % 15)).abs().toString().padLeft(2, '0')} AM",
        "Sunrise": "06:${(58 - (i % 20)).abs().toString().padLeft(2, '0')} AM",
        "Dhuhr": "12:${(26 + (i % 10)).toString().padLeft(2, '0')} PM",
        "Asr": "03:${(29 + (i % 15)).toString().padLeft(2, '0')} PM",
        "Maghrib": "05:${(51 + (i % 20)).toString().padLeft(2, '0')} PM",
        "Isha": "07:${(20 + (i % 15)).toString().padLeft(2, '0')} PM",
      });
    }
    return list;
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
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
    final filteredList = _yearPrayerTimes.where((item) {
      return item["dateLabel"]
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search date (e.g. Oct 19, Jan 1)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final String dateKey = item["dateLabel"];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const Divider(),
                        _buildPrayerRow(dateKey, "Fajr", item["Fajr"]),
                        _buildPrayerRow(dateKey, "Sunrise", item["Sunrise"]),
                        _buildPrayerRow(dateKey, "Dhuhr", item["Dhuhr"]),
                        _buildPrayerRow(dateKey, "Asr", item["Asr"]),
                        _buildPrayerRow(dateKey, "Maghrib", item["Maghrib"]),
                        _buildPrayerRow(dateKey, "Isha", item["Isha"]),
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

  Widget _buildPrayerRow(String dateKey, String prayerName, String time) {
    String alarmKey = "$dateKey-$prayerName";
    bool isAlarmOn = _alarms[alarmKey] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$prayerName: $time",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up, size: 20, color: Colors.teal),
                tooltip: "Preview Azan Sound",
                onPressed: () => _playAzanSound(prayerName),
              ),
              Switch(
                value: isAlarmOn,
                activeThumbColor: Colors.teal,
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
