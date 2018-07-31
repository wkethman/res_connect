import 'package:flutter/material.dart';

class Preference {
  String defaultProgramTag;
  bool authenticated;
  String defaultHospitalTag;
  bool hiddenCall;
  List<String> favorites;

  Preference(this.defaultProgramTag, this.authenticated, this.favorites, {this.defaultHospitalTag, this.hiddenCall = false});
}

class Program {
  String name;
  String tag;
  String passcode;
  Color primaryColor;
  Color accentColor;
  Color lightColor;
  Color darkColor;
  List<Hospital> hospitalList;

  //Program(this.name, this.tag, this.primaryColor, this.accentColor, this.lightColor, this.darkColor, {this.hospitalList});

  Program(this.name, this.tag, this.passcode, List primaryColor, List accentColor, List lightColor, List darkColor, {this.hospitalList}) {
    this.primaryColor = new Color.fromARGB(
        255,
        int.parse(primaryColor[0].toString()),
        int.parse(primaryColor[1].toString()),
        int.parse(primaryColor[2].toString())
    );
    this.accentColor = new Color.fromARGB(
        255,
        int.parse(accentColor[0].toString()),
        int.parse(accentColor[1].toString()),
        int.parse(accentColor[2].toString())
    );
    this.lightColor = new Color.fromARGB(
        255,
        int.parse(lightColor[0].toString()),
        int.parse(lightColor[1].toString()),
        int.parse(lightColor[2].toString())
    );
    this.darkColor = new Color.fromARGB(
        255,
        int.parse(darkColor[0].toString()),
        int.parse(darkColor[1].toString()),
        int.parse(darkColor[2].toString())
    );
  }

  Program addHospitalList(List<Hospital> temp) {
    this.hospitalList = temp;
    return this;
  }
}

class Hospital {
  String tag;
  String name;
  String program;
  List<Number> numberList;

  //Constructors
  Hospital(this.tag, this.name, this.program, this.numberList);

//Functions
}

class Category {
  String name;

  List<Number> categoryNumList;

  //Constructors
  Category(this.name, {this.categoryNumList});

//Functions
}

class Number {
  String uid;
  String program;
  String hospital;
  String category;
  String displayText;
  String preFix;
  String extension;
  bool approved;
  bool flagged;
  bool isPager;
  bool favorite;

  //Constructors
  Number(this.uid, this.program, this.hospital, this.category, this.displayText, this.preFix, this.extension, this.approved, this.flagged, this.isPager, this.favorite);
}

class LinkDisplay {
  String name;
  String program;
  String url;
  int order;

  //Constructors
  LinkDisplay(this.name, this.program, this.url, this.order);

//Functions
}