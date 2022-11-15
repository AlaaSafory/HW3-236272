import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:math';
import 'user-state-management.dart';
import 'package:file_picker/file_picker.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override

  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthorizedUserNotifier>(
      create:  (_) => AuthorizedUserNotifier.instance(),
      child: Consumer<AuthorizedUserNotifier>(
        builder: (context, _login, _) =>

            MaterialApp(
              title: 'Startup Name Generator',
              theme: ThemeData(
                primaryColor: Colors.deepPurple,
                primarySwatch: Colors.deepPurple,

              ),
              home: const RandomWords(),
            ),
      ),
    );
  }
}
class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class DefaultGrabbing extends StatefulWidget {
  late AuthorizedUserNotifier firebaseUser;
  final Color color;
  final bool reverse;
  final SnappingSheetController snappingSheetController;
  DefaultGrabbing(
      {Key? key, this.color = Colors.grey, this.reverse = false,required this.firebaseUser,required this.snappingSheetController})
      : super(key: key);

  @override
  State<DefaultGrabbing> createState() => _DefaultGrabbingState();
}

class _DefaultGrabbingState extends State<DefaultGrabbing> {
  bool closed=true;

  @override
  Widget build(BuildContext context) {
    return
      InkWell(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                spreadRadius: 10,
                color: Colors.black.withOpacity(0.15),
              )
            ],
            /*  borderRadius: _getBorderRadius(),*/
            color: widget.color,
          ),
          child: Transform.rotate(
            angle: widget.reverse ? pi : 0,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment(0, -0.5),
                  child: Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(10),
                    child:  Row( children :  <Widget> [Text(" Welcome back, ${widget.firebaseUser.userEmail()}",
                      style: const TextStyle(fontSize: 18.0),
                      // textAlign: TextAlign.center,
                    ),
                      Expanded(
                        child: Container(
                          color: Colors.grey,
                          width: 100,
                        ),
                      ),
                      IconButton(onPressed:() {
                        if(closed) {setState(() {
                        widget.snappingSheetController.snapToPosition(
                            SnappingPosition.factor(positionFactor: 0.21) );
                        closed = false;});
                      } else {
                        setState(() {

                          widget.snappingSheetController.snapToPosition(
                              SnappingPosition.factor(positionFactor: 0.05));
                          closed = true; });
                      }

                      }, icon: Icon(Icons.expand_less )),]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap:() {

          if(closed) {setState(() {
          widget.snappingSheetController.snapToPosition(
          const SnappingPosition.factor(positionFactor: 0.21) );
          closed = false;});
          } else {
    setState(() {

    widget.snappingSheetController.snapToPosition(
                const SnappingPosition.factor(positionFactor: 0.05));
            closed = true; });
          }

    },
      );
  }
}

class DummyContent extends StatelessWidget {
  final bool reverse;
  final ScrollController? controller;
  late AuthorizedUserNotifier firebaseUser;

  DummyContent({Key? key, this.controller, this.reverse = false,required this.firebaseUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child:
      Column(
          children:  <Widget>[
      Row(
        children:  <Widget>[
          FutureBuilder(future: firebaseUser.userPFP(),
            builder: (BuildContext context,
                AsyncSnapshot<String> snapshot){
              if(snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return Container(
                    padding: const EdgeInsets.all(5),
                    child: CircleAvatar(
                        radius: 42,
                        backgroundImage: NetworkImage(snapshot.data!)
                    )
                );
              }
              return Container(
                  padding: const EdgeInsets.all(5),
                  child: const CircleAvatar(
                  radius: 42.0,
                  )
              );
            },
          ),
          Column(
            children:  <Widget>[
              Text(firebaseUser.userEmail().toString()),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  final newpfp= await FilePicker.platform.pickFiles(
                      allowMultiple: false,
                      type: FileType.custom,
                      allowedExtensions: ['png','jpg','jpeg']
                  );
                  if (newpfp == null){
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text( 'No image selected')
                      ),
                    );
                  }
                  final path = newpfp?.files.single.path;
               /*   final pfpName= newpfp?.files.single.name;*/
                  firebaseUser.uploadPFP(path!);


                },
                child: const Text('Change avatar'),
              ),


            ],
          ),
        ],

      ),
      ],
      ),
    );
  }
}

class BackGround extends StatefulWidget {
  final biggerFont = const TextStyle(fontSize: 18);
  late AuthorizedUserNotifier firebaseUser;
  final saved;
  final suggestions;
  BackGround({Key? key, @required this.saved,@required this.suggestions,required this.firebaseUser}) : super(key: key);

  @override
  State<BackGround> createState() => _BackGroundState();
}

class _BackGroundState extends State<BackGround> {
  @override
  Widget build(BuildContext context) {
    return  ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider();

          final index = i ~/ 2;
          if (index >= widget.suggestions.length) {
            widget.suggestions.addAll(generateWordPairs().take(10));
          }

          bool savedINDatabase=false;
          if(widget.firebaseUser.isAuthenticated){
            var temp =widget.firebaseUser.getCurrentList();
            if(temp!=null){
              savedINDatabase = temp.contains(widget.suggestions[index]);
            }
          }
          final alreadySaved= widget.saved.contains(widget.suggestions[index])||savedINDatabase;
          if (alreadySaved&&!savedINDatabase){
            widget.firebaseUser.updateSavedList(widget.suggestions[index],true);
          }


          return ListTile(
            title: Text(
              widget.suggestions[index].asPascalCase,
              style: widget.biggerFont,
            ),
            trailing: Icon(
              alreadySaved ? Icons.favorite : Icons.favorite_border,
              color: alreadySaved? Colors.red : null,
              semanticLabel: alreadySaved? 'Remove from saved' : 'Save',
            ),
            onTap: () {
              setState(() {
                if(alreadySaved) {
                  widget.saved.remove(widget.suggestions[index]);
                  widget.firebaseUser.updateSavedList(widget.suggestions[index],false);

                } else {
                  widget.saved.add(widget.suggestions[index]);
                  widget.firebaseUser.updateSavedList(widget.suggestions[index],true);

                }
              });
            },
          );
        }
    );
  }
}


class _RandomWordsState extends State<RandomWords> {
  final _biggerFont = const TextStyle(fontSize: 18);
  late AuthorizedUserNotifier firebaseUser;
  final _saved = <WordPair>{};
  final _suggestions = <WordPair>[];
  final snappingSheetController = SnappingSheetController();


  void _pushSaved() async{
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) {
        var temp=firebaseUser.getCurrentList();
        var unioniedSaved=_saved;
        if(firebaseUser.isAuthenticated&& temp!=null){
          unioniedSaved= _saved.union(temp);
        }
        final tiles = unioniedSaved.map(
                (wordPair) {
              return Dismissible(
                key: ValueKey<WordPair>(wordPair),
                background: Container(
                  color: Colors.deepPurple,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.white),
                        Text('Delete suggestion',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                onDismissed: (DismissDirection direction) {
                  setState(() {
                    _saved.remove(wordPair);
                    if (firebaseUser.isAuthenticated) {
                      firebaseUser.updateSavedList(wordPair,false);
                    }}
                  );

                },

                confirmDismiss: (DismissDirection direction) async {
                  String toWrite = wordPair.asPascalCase;
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(

                        title: const Text("Delete Confirmation"),
                        content: Text("Are you sure you want to delete "
                            " $toWrite from your saved suggestions?"),
                        actions: <Widget>[
                          ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text("Yes")
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("No"),
                          ),
                        ],
                      );
                    },
                  );
                },

                child: ListTile(
                  title: Text(
                    wordPair.asPascalCase,
                    style: _biggerFont,
                  ),
                ),
              );
            }
        );
        final divided = tiles.isNotEmpty
            ? ListTile.divideTiles(
          context: context,
          tiles: tiles,
        ).toList()
            : <Widget>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Suggestions'),
          ),
          body: ListView(children: divided),

        );
      },
    ),);
  }

  @override
  Widget build(BuildContext context) {
    firebaseUser =Provider.of<AuthorizedUserNotifier>(context);

    return Scaffold(   // NEW from here ...
        appBar: AppBar(
          title: const Text('Startup Name Generator'),
          actions: [
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: _pushSaved,
              tooltip: 'Saved Suggestions',
            ),
            IconButton(
              icon: firebaseUser.isAuthenticated? const Icon(Icons.exit_to_app):const Icon(Icons.login),
              onPressed: firebaseUser.isAuthenticated? () {
                firebaseUser.signOut();

                SnackBar snackBar = SnackBar(

                  content: const Text(
                      'Successfully logged out'),
                  action: SnackBarAction(
                    label: "UNDO",
                    onPressed: () {
                    },
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                    snackBar);


                Navigator.of(context).popUntil((route) => route.isFirst);
              }:  () {Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  LogIn()),
              );},
              tooltip:firebaseUser.isAuthenticated? 'Logout':'Login',
            )
          ],

        ),
        body: firebaseUser.isAuthenticated? SnappingSheet(

          grabbingHeight: 75,
          snappingPositions: const [
          SnappingPosition.factor(
          positionFactor: 0.0,
          snappingCurve: Curves.easeOutExpo,
          snappingDuration: Duration(seconds: 1),
          grabbingContentOffset: GrabbingContentOffset.top,
          ),
           SnappingPosition.factor(
          positionFactor: 0.21,
          snappingDuration: Duration(seconds: 1),
         ),
          ],
          grabbing:DefaultGrabbing(firebaseUser:firebaseUser, snappingSheetController: snappingSheetController),
          sheetBelow: SnappingSheetContent(

            draggable: true,
            child: DummyContent(
              firebaseUser: firebaseUser,
            ),
          ),
          controller: snappingSheetController,
          child: BackGround(saved:_saved, suggestions:_suggestions,firebaseUser:firebaseUser),
        ):BackGround(saved:_saved, suggestions:_suggestions,firebaseUser:firebaseUser)
    );
  }
}

class LogIn extends StatefulWidget {
  const LogIn({Key? key}) : super(key: key);

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  @override
  Widget build(BuildContext context) {
    bool matched = true;

    final firebaseUser = Provider.of<AuthorizedUserNotifier>(context);
    TextEditingController passCtrler = TextEditingController();
    TextEditingController emailCtrler = TextEditingController();
    TextEditingController confirmCtrler = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children:  <Widget>[
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text(
                  'Welcome to StartUp Names Generator,please Log in!',
                  style: TextStyle(
                      fontSize: 15),
                )),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: emailCtrler,

                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                obscureText: true,
                controller: passCtrler,

                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            firebaseUser.isAuthenticating?
            const CircularProgressIndicator(
              backgroundColor: Colors.purpleAccent,
              valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
            ):
            Container(
              height: 50,
              width: 270,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ElevatedButton(
                onPressed:
                    () async {
                  bool res = await firebaseUser.signIn(emailCtrler.text.trim(), passCtrler.text.trim());
                  if(res) {Navigator.of(context).popUntil((route) => route.isFirst);}
                  else{
                    SnackBar snackBar = SnackBar(

                      content: const Text(
                          'There was an error logging into the app'),
                      action: SnackBarAction(
                        label: "UNDO",
                        onPressed: () {
                        },
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                        snackBar);

                  }

                }
                ,

                child: const Text('Login'),
              ),



            ),


            const SizedBox(
              height: 30,
            ),
            Container(
                height: 50,
                width: 270,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),

                  child: const Text('New user? Click to Sign up'),
                  onPressed: () async{
                    showModalBottomSheet<void>(
                      // context and builder are
                      // required properties in this widget
                      context: context,
                      builder: (BuildContext context) {
                        // we set up a container inside which
                        // we create center column and display text

                        // Returning SizedBox instead of a Container
                        return AnimatedPadding(
                            padding: MediaQuery
                            .of(context)
                            .viewInsets,
                        duration: const Duration(milliseconds: 2),
                        child: SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Text('Please confirm your password below:'),
                                TextField(
                                  controller: confirmCtrler,
                                  obscureText: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          20.0, 20.0, 20.0, 20.0),
                                        labelText: 'Password',
                                      errorText: (!matched) ? 'Passwords must  match' : null,

                                    )

                                ),
                                ElevatedButton(
                                    onPressed: () async {

                                      if(confirmCtrler.text == passCtrler.text){
                                        // the passwords match then sign up
                                        UserCredential? user = await firebaseUser.signUp(emailCtrler.text.trim(), passCtrler.text.trim());
                                        SnackBar snackBar = SnackBar(
                                          content:user==null? const Text('There was an error while signing up'): const Text ('Successfully signed up'),
                                          action: SnackBarAction(
                                            label: "UNDO",
                                            onPressed: () {
                                            },
                                          ),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                        Navigator.pop(context);
                                        if (user!=null){
                                          Navigator.pop(context);
                                        }
                                      }else{
                                        setState(() {
                                          matched = false;
                                          FocusScope.of(context).unfocus();
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                    child: const Text("confirm")
                                )
                              ],
                            ),
                          ),
                        ),
                        );
                      },
                    );
                  },
                )
            ),

          ],
        ),
      ),

    );
  }
}