import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:share/share.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'contact'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

var refreshKey = GlobalKey<RefreshIndicatorState>();

class _MyHomePageState extends State<MyHomePage> {
  @override
  savebool() async {
    SharedPreferences prefs =
        SharedPreferences.getInstance as SharedPreferences;
    await prefs.setBool("formated", formated);
  }

  final ScrollController _scrollController = ScrollController();
  late bool formated;
  List<Contact> contacts = [];
  bool loading = false;
  int pageCount = 1;
  Future<List<Contact>> _getUsers() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/loadjson/dataset.json");
    var jsonData = json.decode(data);

    for (var u in jsonData) {
      Contact contact = Contact(u["user"], u["phone"], u["check-in"]);
      contacts.add(contact);
    }
    contacts.sort((a, b) {
      return b.checkin.toString().compareTo(a.checkin.toString());
    });
    if (contacts.length == 15) {
      loading = true;
    } else {
      loading = false;
    }
    return contacts;
  }

  late Future<List<Contact>> _future;

  @override
  void initState() {
    _future = _getUsers();
    _loadData();

    super.initState();
  }
  
  
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      formated = prefs.getBool("formated")?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        key: refreshKey,
        onRefresh: refreshList,
        child: FutureBuilder(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return const Center(child: Text("Loading..."));
            } else {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                controller: _scrollController,
                itemCount: contacts.length + 1,
                separatorBuilder: (context, index) {
                  return const Divider(
                    height: 1,
                  );
                },
                itemBuilder: (BuildContext context, int index) {
                  if (index < snapshot.data.length) {
                    if (loading) {
                      const Positioned(
                          left: 0,
                          bottom: 0,
                          height: 80,
                          child: Center(child: CircularProgressIndicator()));
                    }
                    return ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.forward_to_inbox),
                        onPressed: () {
                          Share.share(
                              "${snapshot.data[index].user} - ${snapshot.data[index].phone}",
                              subject: snapshot.data[index].user);
                        },
                      ),
                      title: Text(snapshot.data[index].user),
                      subtitle: Text(snapshot.data[index].phone),
                      // ignore: unrelated_type_equality_checks
                      trailing: formated == true
                          ? Text(snapshot.data[index].checkin)
                          : Text(TimeAgo.timeAgoSinceDate(
                              snapshot.data[index].checkin)),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                          child: Text('You have reached end of the list')),
                    );
                  }
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          formated = !formated;
          refreshbutton();
          savebool();
          print(formated);
        },
        icon: Icon(Icons.save),
        label: Text("change format"),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> refreshList() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }
  Future<void> refreshbutton() async {
    refreshKey.currentState?.show(atTop: false);
    setState(() {});
  }
}

class Contact {
  final String user;
  final String phone;
  final String checkin;

  Contact(this.user, this.phone, this.checkin);
}

class TimeAgo {
  static String timeAgoSinceDate(String dateString,
      {bool numericDates = true}) {
    DateTime notificationDate =
        DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString);
    final date2 = DateTime.now();
    final difference = date2.difference(notificationDate);

    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? "year" : "years"} ago";
    } else if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? "month" : "months"} ago";
    } else if (difference.inDays > 7) {
      return "${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? "week" : "weeks"} ago";
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }
}
