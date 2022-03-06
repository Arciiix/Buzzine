import 'package:buzzine/components/alarm_card.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Carousel extends StatefulWidget {
  final List<Widget> children;
  final double? height;
  final Function onSelect;
  final bool? isNap;

  const Carousel(
      {Key? key,
      required this.children,
      this.height,
      required this.onSelect,
      this.isNap})
      : super(key: key);

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    if (widget.children.isNotEmpty) {
      return Column(children: [
        InkWell(
            onTap: () => widget.onSelect(_current),
            child: CarouselSlider(
              carouselController: _controller,
              options: CarouselOptions(
                  height: widget.height ?? 300,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  }),
              items: widget.children.map((element) {
                return Builder(
                  builder: (BuildContext context) {
                    return element;
                  },
                );
              }).toList(),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.children.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: Container(
                width: 8.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                        .withOpacity(_current == entry.key ? 0.9 : 0.4)),
              ),
            );
          }).toList(),
        ),
      ]);
    } else {
      return InkWell(
          onTap: () => widget.onSelect(null),
          child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(5),
              height: widget.height ?? 300,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(
                      widget.isNap == true
                          ? "Brak nadchodzących drzemek!"
                          : "Brak nadchodzących alarmów!",
                      style: TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                        onPressed: () => widget.onSelect(null),
                        child: Text(
                            widget.isNap == true
                                ? "Zarządzaj drzemkami"
                                : "Zarządzaj alarmami",
                            style: TextStyle(fontSize: 24)))
                  ]))));
    }
  }
}
