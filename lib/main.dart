import 'package:flutter/material.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Day counting Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 1. Extend [ConsumerStatefulWidget]
class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// 2. Extend [ConsumerState]
class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 3. use ref.watch() to get the value of the provider
    final dateRange = ref.watch(dateRangeProvider.notifier);
    final weekdays = dateRange.countDays();
    final weekends = dateRange.countWeekends();
    final userInput = ref.watch(userInputProvider);
    final userInputVal = int.tryParse(userInput) ?? 0;
    final max = weekdays + weekends - userInputVal;
    final _controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fairy Bros' Golden Giveaway"),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  width: 250,
                  height: 120,
                  // color: Colors.blue,
                  child: Column(
                    children: [
                      DateTimePicker(
                        dateHintText: 'Start: 2022 / 02 / 09',
                        // dateLabelText: 'Start',
                        icon: Icon(
                          Icons.event,
                          color: Theme.of(context).primaryColor,
                        ),
                        dateMask: 'yyyy / MM / dd',
                        type: DateTimePickerType.date,
                        firstDate: DateTime(2022, 1, 1),
                        lastDate: DateTime(2022, 7, 1),
                        onChanged: (selectedDate) {
                          ref
                              .read(beginDateProvider.notifier)
                              .updateDate(selectedDate);
                        },
                      ),
                      DateTimePicker(
                        icon: Icon(
                          Icons.event,
                          color: Theme.of(context).primaryColor,
                        ),
                        firstDate: DateTime(2022, 1, 1),
                        lastDate: DateTime(2022, 7, 1),
                        dateHintText: 'End: 2022 / 06 / 14',
                        // dateLabelText: 'End',
                        onChanged: (selectedDate) {
                          ref
                              .read(endDateProvider.notifier)
                              .updateDate(selectedDate);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              if (weekdays > 0)
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(
                        'Total stamps: ${weekdays + weekends}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                              'There are $weekdays days between selected dates.'),
                          Text(
                              'There are $weekends weekends between selected dates.'),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(
                height: 30,
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 250,
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    decoration: InputDecoration(
                      labelText: "Missed days",
                      icon: Icon(
                        Icons.numbers,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onFieldSubmitted: (text) {
                      ref.read(userInputProvider.state).update((state) => text);
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Card(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Maximum achievable: $max'),
                    subtitle: Text('Total missed days: $userInput'),
                    trailing: (max >= 144)
                        ? const Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final userInputProvider = StateProvider<String>((ref) {
  return '0';
});

final beginDateProvider = StateNotifierProvider<FairyDate, DateTime>((ref) {
  return FairyDate(2022, 2, 9);
});
final endDateProvider = StateNotifierProvider<FairyDate, DateTime>((ref) {
  return FairyDate(2022, 6, 14);
});

final dateRangeProvider =
    StateNotifierProvider<FairyDateRange, DateTimeRange>((ref) {
  final begin = ref.watch(beginDateProvider);
  final end = ref.watch(endDateProvider);
  return FairyDateRange(begin, end);
});

class FairyDateRange extends StateNotifier<DateTimeRange> {
  FairyDateRange(DateTime begin, DateTime end)
      : super(DateTimeRange(start: begin, end: end)) {
    state = super.state;
  }

  int countDays() {
    return state.duration.inDays;
  }

  int countWeekends() {
    int nbDays = state.duration.inDays;
    if (nbDays == 0) return 0;
    List<int> days = List.generate(nbDays, (index) {
      int weekDay =
          DateTime(state.start.year, state.start.month, state.start.day + index)
              .weekday;
      if (weekDay == DateTime.saturday || weekDay == DateTime.sunday) {
        return 1;
      }
      return 0;
    });
    return days.reduce((a, b) => a + b);
  }
}

class FairyDate extends StateNotifier<DateTime> {
  FairyDate([int year = 2022, int month = 2, int day = 9])
      : super(DateTime(year, month, day)) {
    state = DateTime(year, month, day);
  }
  void updateDate(String dateString) {
    state = DateTime.parse(dateString);
  }

  void clearDate() {
    state = DateTime.now();
  }
}
