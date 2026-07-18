import 'package:flutter/material.dart';
import 'package:scheduling/main.dart';
import 'package:scheduling/style/color.dart';

class CardList extends StatefulWidget {
  final String? title, text, textInfo;
  final dynamic onTap, iconButton, onLongPress;
  const CardList({
    super.key,
    this.title,
    this.text,
    this.textInfo,
    this.onTap,
    this.iconButton,
    this.onLongPress,
  });

  @override
  State<CardList> createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        //margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ColorsApp.primaryColor,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                widget.iconButton ?? SizedBox(),
                textCard(widget.textInfo ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget textCard(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 10, color: ColorsApp.secondaryColor),
    );
  }

  Widget titleCard(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: ColorsApp.secondaryColor,
      ),
    );
  }
}
