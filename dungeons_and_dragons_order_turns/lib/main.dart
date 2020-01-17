import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int current_turn = 0;
  @override
  Widget build(BuildContext context) {
    final db = Firestore.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("MainScreen"),
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
                      if(newData['Turn'] == 0)
                      newData['Turn'] = snapshot.documents.length;
                      ds.reference.updateData(newData);
                      if(ds.data['OriginalFirst'] && newData['Turn'] == 1)
                      {
                        setState(() {
                          ++current_turn;
                        });
                      }
                    }
                  });
                },
              ),
              Text("Turn: $current_turn"),
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
