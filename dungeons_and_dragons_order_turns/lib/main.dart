import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class AddCharacterPage extends StatefulWidget {
  @override
  _AddCharacterPageState createState() => _AddCharacterPageState();
}

class _AddCharacterPageState extends State<AddCharacterPage> {
  TextEditingController _controllerName;
  int _initiativeModifier = 0;

  @override
  void initState() {
    _controllerName = new TextEditingController();
    _initiativeModifier = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Character"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text("Put Your Character Name:"),
              TextField(
                controller: _controllerName,
              ),
            ],
          ),
          Column(
            children: <Widget>[
              Text("Your initiative modifier"),
              Container(
                margin: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(border: Border.all()),
                padding: EdgeInsets.only(left: 10),
                width: 110,
                height: 100,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _initiativeModifier.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        ButtonTheme(
                          minWidth: 25,
                          height: 25,
                          child: FlatButton(
                            child: Icon(Icons.arrow_upward),
                            color: Colors.grey[300],
                            onPressed: () {
                              setState(() {
                                if (_initiativeModifier != 99)
                                  ++_initiativeModifier;
                              });
                            },
                          ),
                        ),
                        ButtonTheme(
                          minWidth: 25,
                          height: 25,
                          child: FlatButton(
                            child: Icon(Icons.arrow_downward),
                            color: Colors.grey[300],
                            onPressed: () {
                              setState(() {
                                if (_initiativeModifier != -99)
                                  --_initiativeModifier;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          FlatButton(
            color: Colors.red[100],
            child: Text("Add Character"),
            onPressed: () {
              final db = Firestore.instance;

              Map<String, dynamic> data = new Map<String, dynamic>();
              data['CharacterName'] = _controllerName.text;
              var randomGenerator = new Random();
              int randomValue =
                  randomGenerator.nextInt(20) + 1; //Dice of 20 faces
              data['InitiativeValue'] = randomValue + _initiativeModifier;
              db
                  .collection('Characters')
                  .orderBy('Turn')
                  .getDocuments()
                  .then((snapshots) {
                if (snapshots.documents.isEmpty) {
                  data['OriginalFirst'] = true;
                  data['Turn'] = 1;
                } else {
                  data['OriginalFirst'] = false;
                  data['Turn'] = -1;
                  for (DocumentSnapshot ds in snapshots.documents) {
                    if (ds.data['InitiativeValue'] < data['InitiativeValue']) {
                      if (data['Turn'] == -1) data['Turn'] = ds.data['Turn'];

                      ds.data['Turn'] = ds.data['Turn'] + 1;
                      db.collection('Characters').document(ds.documentID).updateData(ds.data);
                    } else {
                      if (ds == snapshots.documents.last)
                        data['Turn'] = ds.data.length + 1;
                      else
                        continue;
                    }
                  }
                }
                db.collection('Characters').add(data);
                Navigator.of(context).pop();
              });
            },
          )
        ],
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = Firestore.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("MainScreen"),
      ),
      body: StreamBuilder(
        stream: db.collection('Characters').orderBy("Turn").snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          List<DocumentSnapshot> docs = snapshot.data.documents;
          return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(docs[index].data["CharacterName"]),
                  subtitle:
                      Text(docs[index].data["InitiativeValue"].toString()),
                  trailing: FlatButton(
                    shape: CircleBorder(
                        side: BorderSide(
                            color: Colors.white.withAlpha(0), width: 20)),
                    child: Icon(Icons.delete),
                    onPressed: () {
                      db
                          .collection('Characters')
                          .document(docs[index].documentID)
                          .delete();
                    },
                  ),
                );
              });
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddCharacterPage(),
          ));
        },
      ),
    );
  }
}

class CombatPage extends StatefulWidget {
  @override
  _CombatPageState createState() => _CombatPageState();
}

class _CombatPageState extends State<CombatPage> {
  int currentTurn = 0;
  @override
  Widget build(BuildContext context) {
    final db = Firestore.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Combat!"),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                color: Colors.pink[100],
                child: Text("Pass Turn"),
                onPressed: () {
                  db.collection('Characters').getDocuments().then((snapshot) {
                    for (DocumentSnapshot ds in snapshot.documents) {
                      Map<String, dynamic> newData = new Map<String, dynamic>();
                      newData['Turn'] = ds.data['Turn'] - 1;
                      if (newData['Turn'] == 0)
                        newData['Turn'] = snapshot.documents.length;
                      ds.reference.updateData(newData);
                      if (ds.data['OriginalFirst'] && newData['Turn'] == 1) {
                        setState(() {
                          ++currentTurn;
                        });
                      }
                    }
                  });
                },
              ),
              Text("Turn: $currentTurn"),
            ],
          ),
          Expanded(
            child: StreamBuilder(
              stream: db.collection('Characters').orderBy("Turn").snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                List<DocumentSnapshot> docs = snapshot.data.documents;
                return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(docs[index].data["CharacterName"]),
                        subtitle: Text(
                            docs[index].data["InitiativeValue"].toString()),
                      );
                    });
              },
            ),
          ),
        ],
      ),
    );
  }
}
