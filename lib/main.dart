
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:res_connect/models.dart';
import 'package:res_connect/data.dart';

List<LinkDisplay> linkList = [];
List<Hospital> hospitalList = [];
List<Category> categoryList = [];
List<Number> numberList = [];
List<Program> programList = [];
Preference defaultPref;
Program defaultProgram;

class HomePage extends StatefulWidget {
  final SharedPreferences pref;

  HomePage(this.pref);

  @override
  State<StatefulWidget> createState() {
    return new _HomePageState(pref);
  }
}

class _HomePageState extends State<HomePage> {
  final SharedPreferences pref;
  bool _isSearching = false;
  final TextEditingController _searchQuery = new TextEditingController();

  _HomePageState(this.pref);

  Future<Null> _aboutApp() {
    return showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text('About application'),
            content: new SingleChildScrollView(
              child: new ListBody(
                children: <Widget>[
                  new Text(aboutText),
                ],
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                }
              ),
            ],
          );
        }
    );
  }

  int _defaultHosp() {
    if(defaultPref.defaultHospitalTag != null) {
      return hospitalList.indexWhere((hosp) => hosp.tag == defaultPref.defaultHospitalTag);
    } else {
      return 0;
    }
  }

  void _handleSearchEnd() {
    Navigator.pop(context);
  }

  void _handleSearchBegin() {
    ModalRoute.of(context).addLocalHistoryEntry(new LocalHistoryEntry(
      onRemove: () {
        setState(() {
          _isSearching = false;
          _searchQuery.clear();
        });
      },
    ));
    setState(() {
      _isSearching = true;
    });
  }

  List<Category> _buildCategoryList(List<Number> numbers) {
    List<Category> returnCatList = [];

    categoryList.forEach((Category cat) {
      List<Number> tempNumList = [];
      if(cat.name == "Favorites") {
        tempNumList = numbers.where((Number num) => (num.favorite == true)).toList();
      } else {
        tempNumList = numbers.where((Number num) => (num.category == cat.name)).toList();
      }
      if(tempNumList.isNotEmpty) {
        returnCatList.add(new Category(cat.name, categoryNumList: tempNumList));
      }
    });
    return returnCatList;
  }

  List<Number> _filterBySearchQuery(List<Number> numbers) {
    if (_searchQuery.text.isEmpty)
      return numbers;
    final RegExp regexp = new RegExp(_searchQuery.text, caseSensitive: false);
    return numbers.where((Number num) => num.displayText.contains(regexp)).toList();
  }

  Widget _buildHospTab(BuildContext context, Hospital tempHosp) {
    return new AnimatedBuilder(
      animation: new Listenable.merge(<Listenable>[_searchQuery]),
      builder: (BuildContext context, Widget child) {
        List<Number> tempNumList = _filterBySearchQuery(tempHosp.numberList);
        List<Category> catList = _buildCategoryList(tempNumList);

        return new ListView.builder(
          itemBuilder: (context, int index) => _buildCat(context, catList[index]),
          itemCount: catList.length,
        );
      }
    );
  }

  void _changeFlag(Number number) {
    setState(() {
      bool temp = number.flagged;
      number.flagged = !temp;
      Firestore.instance.collection('numbers').document(number.uid).updateData({'flagged' : !temp});
    });
  }

  void _changeFavorite(Number number) {
    setState(() {
      bool temp = number.favorite;
      if(temp) {
        defaultPref.favorites.removeWhere((favorite) => favorite == number.uid);
      } else {
        defaultPref.favorites.add(number.uid);
      }
      pref.setStringList('favorites', defaultPref.favorites);
      number.favorite = !temp;
    });
  }

  Widget _buildNumber(Number number) {
    return new Container(
        padding: const EdgeInsets.all(8.0),
        child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              new IconButton(
                padding: const EdgeInsets.only(right: 8.0),
                icon: new Icon(Icons.phone, color: defaultProgram.primaryColor),
                iconSize: 25.0,
                onPressed: () {
                  if (defaultPref.hiddenCall) {
                    launchLink("tel:*67${number.preFix + number.extension}");
                  } else {
                    launchLink("tel:${number.preFix + number.extension}");
                  }
                  }
              ),
              new Expanded(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget> [
                    new Text(number.displayText, style: TextStyle(color: defaultProgram.darkColor, fontSize: 16.0)),
                    new Text((number.extension == "null" ? number.preFix : number.extension), style: TextStyle(color: defaultProgram.darkColor))
                  ]
                )
              ),
              /*new IconButton(
              icon: new Icon(Icons.edit),
              onPressed: null
            ),*/
              new IconButton(
                tooltip: "Favorite this number",
                icon: number.favorite ? new Icon(Icons.star, color: defaultProgram.primaryColor) : new Icon(Icons.star_border, color: defaultProgram.lightColor),
                onPressed: () { _changeFavorite(number); }
              ),
              new IconButton(
                tooltip: "Flag for deletion or edit",
                icon: new Icon(Icons.warning, color: number.flagged ? defaultProgram.primaryColor : defaultProgram.lightColor),
                onPressed: () { _changeFlag(number); }
              )
            ]
        )
    );
  }

  Widget _buildCat(BuildContext context, Category category) {
    return new ExpansionTile(
      initiallyExpanded: category.name == "Favorites" ? true : false,
      title: new Text(category.name),
      children: category.categoryNumList.map(_buildNumber).toList()
    );
  }

  Widget buildDefaultBar() {
    return new AppBar(
      title: new Text('Res Connect'),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.search),
          tooltip: 'Search numbers',
          onPressed: _handleSearchBegin,
        ),
        new IconButton(
          icon: new Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.pushNamed(context, "/settings");
          },
        ),
        new IconButton(
          icon: new Icon(Icons.info),
          tooltip: 'App information',
          onPressed: _aboutApp
        )
      ],
      bottom: new TabBar(
        isScrollable: true,
        tabs: hospitalList.map((Hospital hosp) {
          return new Tab(
            text: hosp.tag,
          );
        }).toList(),
      ),
    );
  }

  Widget buildSearchBar() {
    return new AppBar(
      title: new Text('Res Connect'),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.close),
          tooltip: 'Cancel search',
          onPressed: _handleSearchEnd,
        ),
        new IconButton(
          icon: new Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.pushNamed(context, "/settings");
          },
        ),
        new IconButton(
            icon: new Icon(Icons.info),
            tooltip: 'App information',
            onPressed: _aboutApp
        )
      ],
      bottom: new PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: new Padding(
          padding: EdgeInsets.only(left: 15.0, right: 15.0),
          child: new TextField(
            controller: _searchQuery,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15.0),
            decoration: const InputDecoration(
              hintStyle: const TextStyle(color: Colors.white, fontSize: 15.0),
              hintText: 'Search numbers',
            )
          )
        )
      )
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return new Drawer(
        child: new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 40.0, 0.0, 0.0),
                child: new Text("Resources", style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0)),
              ),
              new Flexible(
                child: new ListView.builder(
                  padding: const EdgeInsets.fromLTRB(5.0, 10.0, 0.0, 0.0),
                  itemExtent: 45.0,
                  itemBuilder: (BuildContext context, int index) => new _LinkItem(linkList[index]),
                  itemCount: linkList.length
                )
              )
            ]
        )
    );
  }

  Widget _buildFloatingActionButton() {
    return new FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, "/addNumber");
      },
      tooltip: "Add number",
      child: new Icon(Icons.add, color: Colors.white)
    );
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      initialIndex: _defaultHosp(),
      length: hospitalList.length,
      child: new Scaffold(
        drawer: _buildDrawer(context),
        appBar: _isSearching ? buildSearchBar() : buildDefaultBar(),
        body: new TabBarView(
          children: hospitalList.map((Hospital hosp) {
            return new Padding(
              padding: const EdgeInsets.all(5.0),
              child: _buildHospTab(context, hosp)
            );
          }).toList(),
        ),
        floatingActionButton: _buildFloatingActionButton()
      )
    );
  }
}

class _LinkItem extends StatelessWidget {
  final LinkDisplay link;

  Widget _buildLinks(LinkDisplay link) {
    return new ListTile(
      leading: new Icon(Icons.link),
      title: new Text(link.name),
      onTap: () => launchLink(link.url)
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildLinks(link);
  }

  _LinkItem(this.link);
}

class AddNumber extends StatefulWidget {
  //Functions
  @override
  AddNumberState createState() => new AddNumberState();
}

class AddNumberState extends State<AddNumber> {
  final formKey = new GlobalKey<FormState>();

  String hospital;
  String category;
  String displayText;
  String preFix;
  String extension;

  List<Category> tempCategoryList = [];

  AddNumberState();

  Future<Null> _numberSubmitted() {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Thank you!'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('The number you submitted will automatically display within the app after it has been reloaded.'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Ok'),
                onPressed: () {
                  Navigator.of(context).popUntil(ModalRoute.withName('/'));
                }
            ),
          ],
        );
      }
    );
  }

  void _submit() {
    final form = formKey.currentState;

    if (form.validate()) {
      form.save();
      _addNumber();
    }
  }

  void _addNumber() async {
    Firestore.instance.collection('numbers').document().setData({ 'program' : defaultProgram.tag, 'approved' : true, 'category': category, 'displayText' : displayText, 'extension' : extension, 'flagged' : false, 'isPager': false, 'hospital' : hospital, 'prefix': preFix });
    _numberSubmitted();
  }

  @override
  void initState() {
    super.initState();

    hospital = hospitalList[0].tag;
    tempCategoryList = categoryList;
    tempCategoryList.removeWhere((temp) => temp.name == "Favorites");
    category = tempCategoryList[0].name;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Add number')),
      body: new Padding(
        padding: const EdgeInsets.all(16.0),
        child: new Form(
          key: formKey,
          child: new ListView(
            children: [
              new TextFormField(
                decoration: new InputDecoration(
                  counterText: 'Display text',
                  counterStyle: new TextStyle(color: defaultProgram.primaryColor, fontSize: 15.0),
                  icon: new Icon(Icons.contacts, color: defaultProgram.primaryColor)),
                onSaved: (val) => displayText = val,
                autocorrect: true,
                style: new TextStyle(fontSize: 18.0, decorationColor: defaultProgram.darkColor, color: defaultProgram.darkColor),
              ),
              new TextFormField(
                decoration: new InputDecoration(
                  counterText: 'Pre-fix',
                  counterStyle: new TextStyle(color: defaultProgram.primaryColor, fontSize: 15.0),
                  icon: new Icon(Icons.contact_phone, color: defaultProgram.primaryColor)),
                validator: (val) =>
                val.length == 5 ? null : 'Pre-fix is usually no more than 5 characters',
                onSaved: (val) => preFix = val,
                style: new TextStyle(fontSize: 18.0, decorationColor: defaultProgram.darkColor, color: defaultProgram.darkColor),
              ),
              new TextFormField(
                decoration: new InputDecoration(
                  counterText: 'Extension',
                  counterStyle: new TextStyle(color: defaultProgram.primaryColor, fontSize: 15.0),
                  icon: new Icon(Icons.phone, color: defaultProgram.primaryColor)),
                validator: (val) =>
                val.length > 4 ? null : 'Extension is too short',
                onSaved: (val) => extension = val,
                style: new TextStyle(fontSize: 18.0, decorationColor: defaultProgram.darkColor, color: defaultProgram.darkColor),
              ),
              new Center(
                child: new DropdownButton(
                  value: hospital,
                  onChanged: (String newVal) {
                    setState(() { hospital = newVal; });
                  },
                  items: hospitalList.map((Hospital hosp) {
                    return new DropdownMenuItem(
                        child: new Container(
                            child: new Text(hosp.tag),
                            width: 120.0
                        ),
                        value: hosp.tag
                    );
                  }).toList()
                )
              ),
              new Center(
                child: new DropdownButton(
                  value: category,
                  onChanged: (String newVal) {
                    setState(() { category = newVal; });
                  },
                  items: tempCategoryList.map((Category cat) {
                    return new DropdownMenuItem(
                        child: new Container(
                            child: new Text(cat.name),
                            width: 120.0
                        ),
                        value: cat.name
                    );
                  }).toList()
                ),
              ),
              new Divider(
                height: 16.0
              ),
              new RaisedButton(
                onPressed: _submit,
                child: new Text('Create number'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectProgram extends StatefulWidget {
  final SharedPreferences pref;

  SelectProgram(this.pref);

  @override
  SelectProgramState createState() => new SelectProgramState(pref);
}

class SelectProgramState extends State<SelectProgram> {
  final formKey = new GlobalKey<FormState>();

  SharedPreferences pref;
  String programTag;
  String passcode;

  SelectProgramState(this.pref);

  void _submit() {
    final form = formKey.currentState;

    if (form.validate()) {
      form.save();
      _createPref();
    }
  }

  void _createPref() async {
    defaultPref = new Preference(programTag, true, []);
    pref.setString('programTag', programTag);
    pref.setBool('authenticated', true);
    defaultProgram = programList.firstWhere((temp) => temp.tag == programTag);

    runApp(new MaterialApp(
      theme: new ThemeData(
        primaryColor: defaultProgram.primaryColor,
        accentColor: defaultProgram.accentColor,
      ),
      home: new Loading("contacts"),
    ));

    await buildLists(pref);
  }

  @override
  void initState() {
    super.initState();

    programTag = programList[0].tag;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Padding(
        padding: const EdgeInsets.all(16.0),
        child: new Form(
          key: formKey,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              new Center(
                child: new DropdownButton(
                  value: programTag,
                  onChanged: (String newVal) {
                    setState(() { programTag = newVal; });
                  },
                  items: programList.map((Program temp) {
                    return new DropdownMenuItem(
                      child: new Container(
                        child: new Text(temp.name),
                        width: 180.0
                      ),
                      value: temp.tag
                    );
                  }).toList()
                )
              ),
              new Container(
                padding: EdgeInsets.only(bottom: 20.0),
                width: 200.0,
                child: new TextFormField(
                  obscureText: true,
                  decoration: new InputDecoration(
                    counterText: 'Passcode',
                  ),
                  validator: (val) => programList.firstWhere((temp) => temp.tag == programTag).passcode == val ? null : 'Incorrect passcode',
                  onSaved: (val) => passcode = val,
                )
              ),
              new RaisedButton(
                onPressed: _submit,
                child: new Text('Select'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Settings extends StatefulWidget {
  final SharedPreferences pref;

  Settings(this.pref);

  @override

  SettingsPageState createState() => new SettingsPageState(pref);
}

class SettingsPageState extends State<Settings> {
  final formKey = new GlobalKey<FormState>();

  SharedPreferences pref;
  String hospitalTag;
  bool hiddenCall;

  SettingsPageState(this.pref);

  Future<Null> _settingsSubmitted() {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Success'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Your settings have been recorded - please restart the application to load your settings.'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Ok'),
                onPressed: () {
                  Navigator.of(context).popUntil(ModalRoute.withName('/'));
                }
            ),
          ],
        );
      }
    );
  }

  Future<Null> _resetProgram() {
    return showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text('Warning'),
            content: new SingleChildScrollView(
              child: new ListBody(
                children: <Widget>[
                  new Text('Are you sure that you want to reset the application?'),
                ],
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Yes'),
                onPressed: () async {
                  await pref.clear();
                  exit(0);
                }
              ),
              new FlatButton(
                child: new Text('No'),
                onPressed: () {
                  Navigator.of(context).popUntil(ModalRoute.withName('/settings'));
                }
              ),
            ],
          );
        }
    );
  }

  void _submit() {
    final form = formKey.currentState;
    form.save();
    _createPref();
  }

  void _createPref() {
    defaultPref = new Preference(defaultPref.defaultProgramTag, defaultPref.authenticated, defaultPref.favorites, defaultHospitalTag: hospitalTag, hiddenCall: hiddenCall);

    pref.setString('hospitalTag', hospitalTag);
    pref.setBool('hiddenCall', hiddenCall);

    _settingsSubmitted();
  }

  @override
  void initState() {
    super.initState();

    hospitalTag = defaultPref.defaultHospitalTag;
    hiddenCall = defaultPref.hiddenCall;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Settings'),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.refresh),
            tooltip: "Reset program",
            onPressed: _resetProgram
          ),
        ],
      ),
      body: new Padding(
        padding: const EdgeInsets.all(30.0),
        child: new Form(
          key: formKey,
          child: new ListView(
            children: [
              new Center(
                child: new Text("Default hospital", style: new TextStyle(fontSize: 18.0))
              ),
              new Center(
                child: new DropdownButton(
                  value: hospitalTag,
                  onChanged: (String newVal) {
                    setState(() { hospitalTag = newVal; });
                  },
                  items: hospitalList.map((Hospital temp) {
                    return new DropdownMenuItem(
                      child: new Container(
                          child: new Text(temp.tag),
                          width: 120.0
                      ),
                      value: temp.tag
                    );
                  }).toList()
                )
              ),
              new Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: new Center(
                  child: new Text("Hide callback number", style: new TextStyle(fontSize: 18.0))
                ),
              ),
              new Center(
                child: new Switch(
                  value: hiddenCall,
                  onChanged: (bool newVal) {
                    setState(() { hiddenCall = newVal; });
                  },
                )
              ),
              new Divider(
                height: 16.0
              ),
              new RaisedButton(
                onPressed: _submit,
                child: new Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

launchLink(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  }
  else {
    throw 'Could not launch $url';
  }
}

class Loading extends StatelessWidget {
  final String title;

  Loading(this.title);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Text("Loading $title...", style: new TextStyle(fontSize: 18.0)),
      ));
  }
}

Future buildLists(SharedPreferences pref) async {
  //Build linkList
  Future
      .wait([
    Firestore.instance.collection('links').where('program', isEqualTo: defaultProgram.tag).orderBy('order').getDocuments(),
    Firestore.instance.collection('categories').orderBy('order').getDocuments(),
    Firestore.instance.collection('hospitals').where('program', isEqualTo: defaultProgram.tag).orderBy('order').getDocuments(),
    Firestore.instance.collection('numbers').where('program', isEqualTo: defaultProgram.tag).orderBy('displayText').getDocuments()
  ])
      .then((List responses) {
    //Build linkList
    responses[0].documents.forEach((link) {
      linkList.add(new LinkDisplay(link['name'].toString(), link['program'].toString(), link['url'].toString(), link['order']));
    });
    //Build categoryList
    responses[1].documents.forEach((category) {
      categoryList.add(new Category(category['name'].toString()));
    });
    //Build numberList
    responses[3].documents.forEach((number) {
      numberList.add(new Number(
        number.documentID.toString(),
        number['program'].toString(),
        number['hospital'].toString(),
        number['category'].toString(),
        number['displayText'].toString(),
        number['prefix'].toString(),
        number['extension'].toString(),
        number['approved'],
        number['flagged'],
        number['isPager'],
        false
      ));
    });
    defaultPref.favorites.forEach((favorite) {
      numberList.singleWhere((number) => number.uid == favorite).favorite = true;
    });
    //Build hospitalList
    responses[2].documents.forEach((hospital) {
      hospitalList.add(new Hospital(hospital['tag'], hospital['name'], hospital['program'], numberList.where((num) => num.hospital == hospital['tag']).toList()));
    });
    defaultProgram.addHospitalList(hospitalList);

    runApp(new MaterialApp(
      theme: new ThemeData(
        primaryColor: defaultProgram.primaryColor,
        accentColor: defaultProgram.accentColor,
        textSelectionColor: defaultProgram.primaryColor
      ),
      home: new HomePage(pref),
      routes: <String, WidgetBuilder> {
        '/addNumber' : (BuildContext context) => new AddNumber(),
        '/settings' : (BuildContext context) => new Settings(pref),
      },
    ));
  }).catchError((e) => print(e));
}

void uploadJSON() {
  var temp = json.decode(defaultNumbers);

  temp.forEach((num) async {
    Firestore.instance.collection('numbers').add({
      'approved' : num['approved'],
      'program' : num['program'],
      'category': num['category'],
      'displayText' : num['displayText'],
      'extension' : num['extension'],
      'flagged' : num['flagged'],
      'hospital' : num['hospital'],
      'prefix': num['prefix'],
      'isPager' : num['isPager']
    });
  });
}

void main() async {
  //uploadJSON();

  Firestore.instance.collection('programs').getDocuments().then((QuerySnapshot programs) async {
    programs.documents.forEach((program) {
      programList.add(new Program(program['name'], program['tag'], program['passcode'], program['primaryColorRBG'], program['accentColorRBG'], program['lightColorRBG'], program['darkColorRBG']));
    });

    SharedPreferences pref = await SharedPreferences.getInstance();
    String programTag = pref.getString('programTag');

    if (programTag == null) {
      runApp(new MaterialApp(
        home: new SelectProgram(pref),
      ));
    }
    else {
      String hospitalTag = pref.getString('hospitalTag');
      bool hiddenCall = pref.getBool('hiddenCall');
      bool authenticated = pref.getBool('authenticated') ?? false;
      List<String> favorites = pref.getStringList('favorites') ?? [];

      if(authenticated) {
        defaultPref = new Preference(programTag, true, favorites, defaultHospitalTag: hospitalTag ?? null, hiddenCall: hiddenCall ?? false);

        defaultProgram = programList.firstWhere((temp) => temp.tag == programTag);

        runApp(new MaterialApp(
          theme: new ThemeData(
            primaryColor: defaultProgram.primaryColor,
            accentColor: defaultProgram.accentColor,
            textSelectionColor: defaultProgram.primaryColor
          ),
          home: new Loading("contacts"),
        ));

        await buildLists(pref);
      } else {
        runApp(new MaterialApp(
          home: new SelectProgram(pref),
        ));
      }
    }
  });
}