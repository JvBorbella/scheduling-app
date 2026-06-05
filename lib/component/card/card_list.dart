import 'package:flutter/material.dart';

class CardList extends StatefulWidget {
  final String? title, text, textInfo;
  final dynamic onTap, iconButton;
  const CardList({super.key, this.title, this.text, this.textInfo, this.onTap, this.iconButton});

  @override
  State<CardList> createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromRGBO(189, 189, 189, 1), width: 2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleCard(widget.title ?? ''),
              textCard(widget.text ?? ''),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              widget.iconButton,
              textCard(widget.textInfo ?? ''),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget textCard(String text) {
    return Text(text, style: TextStyle(fontSize: 10));
  }

  Widget titleCard(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
