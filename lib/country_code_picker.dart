import 'dart:math';
import 'package:country_code_picker/constants.dart';
import 'package:country_code_picker/country.code.dart';
import 'package:country_code_picker/country.codes.dart';
import 'package:country_code_picker/dimension.dart';
import 'package:country_code_picker/input.field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

export 'country.code.dart';

class CountryCodePicker extends HookWidget {
  const CountryCodePicker({
    super.key,
    this.countryList = codes,
    this.initialSelection,
    this.showModal = false,
    required this.onChanged,
  });

  /// An optional argument for injecting a list of countries
  /// with customized codes.
  final List<Map<String, String>> countryList;

  /// Initial selection accepts [dialCode], [countryCode] or [countryName]
  final String? initialSelection;

  final Function(CountryCode) onChanged;

  final bool showModal;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final elements = useState<List<CountryCode>>([]);
    final selectedItem = useState<CountryCode?>(null);
    final searchController = useTextEditingController();

    useEffect(() {
      elements.value = countryList.map((e) => CountryCode.fromJson(e)).toList();

      //set [selectedItem] based on initialSelection
      if (initialSelection != null) {
        selectedItem.value = elements.value.firstWhere(
            (e) =>
                (e.code!.toUpperCase() == initialSelection!.toUpperCase()) ||
                (e.dialCode == initialSelection) ||
                (e.name!.toUpperCase() == initialSelection!.toUpperCase()),
            orElse: () => elements.value[0]);
      } else {
        selectedItem.value = elements.value[0];
      }
      return null;
    }, []);

    return CupertinoButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(getScreenHeight(2)),
            ),
            child: Image.asset(
              selectedItem.value!.flagUri!,
              package: 'country_code_picker',
              width: getScreenWidth(32),
            ),
          ),
          SizedBox(width: getScreenWidth(5)),
          Transform.rotate(
            angle: -pi / 2,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: getScreenHeight(13),
              color: PRYCOLOUR,
            ),
          )
        ],
      ),
      onPressed: () async {
        if (showModal) {
          return await showCountryPickerModal(
              context, elements.value, searchController, (val) {
            selectedItem.value = val;
            onChanged(val);
          });
        } else {
          CountryCode? countryCode = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenPicker(
                codes: elements.value,
              ),
            ),
          );
          if (countryCode != null) {
            selectedItem.value = countryCode;
            onChanged(countryCode);
          }
        }
      },
    );
  }
}

class FullScreenPicker extends HookWidget {
  const FullScreenPicker({
    super.key,
    required this.codes,
  });

  final List<CountryCode> codes;
  @override
  Widget build(BuildContext context) {
    final filteredCodes = useState<List<CountryCode>>(codes);
    final searchController = useTextEditingController();
    return Scaffold(
      backgroundColor: WHTBGCOLOUR,
      body: Padding(
        padding: EdgeInsets.only(
          right: getScreenWidth(30),
          left: getScreenWidth(30),
          top: getScreenHeight(70),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupertinoButton(
              minSize: 0,
              padding: EdgeInsets.zero,
              alignment: Alignment.topLeft,
              child: const Icon(
                Icons.close_sharp,
                color: Color(0xFF1D232E),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: getScreenHeight(27)),
            InputField(
              hint: 'Search for a country',
              controller: searchController,
              label: '',
              autofocus: false,
              prefix: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getScreenWidth(12),
                ),
                child: Icon(Icons.search,
                    size: getScreenHeight(25), color: const Color(0xFFDADADA)),
              ),
              onChanged: (value) {
                final val = value.toUpperCase();
                if (value.isNotEmpty) {
                  filteredCodes.value = codes
                      .where((e) =>
                          e.code!.contains(val) ||
                          e.dialCode!.contains(val) ||
                          e.name!.toUpperCase().contains(val))
                      .toList();
                  if (filteredCodes.value.isEmpty) filteredCodes.value = codes;
                }
              },
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: CustomScrollBehavior(),
                child: ListView.builder(
                  itemCount: filteredCodes.value.length,
                  itemBuilder: (context, index) {
                    final data = filteredCodes.value[index];
                    return CupertinoButton(
                      onPressed: () {
                        Navigator.pop(context, data);
                      },
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        dense: true,
                        minLeadingWidth: getScreenWidth(18),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: getScreenHeight(3),
                        ),
                        leading: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              getScreenHeight(2),
                            ),
                          ),
                          child: Image.asset(
                            data.flagUri!,
                            package: 'country_code_picker',
                            width: getScreenWidth(24),
                          ),
                        ),
                        title: Text(
                          data.name ?? '',
                          style: GoogleFonts.inter(
                              fontSize: getScreenHeight(16),
                              color: const Color(0xFF1C1C1E)),
                        ),
                        trailing: Text(
                          data.dialCode ?? '',
                          style: GoogleFonts.inter(
                              fontSize: getScreenHeight(16),
                              color: const Color(0xFF1C1C1E)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

Future<void> showCountryPickerModal(
  BuildContext context,
  List<CountryCode> codes,
  TextEditingController searchController,
  Function(CountryCode) onChanged,
) {
  List<CountryCode> filteredCodes = codes;

  return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(5),
          topLeft: Radius.circular(5),
        ),
      ),
      backgroundColor: WHTBGCOLOUR,
      builder: (context) {
        return StatefulBuilder(builder: (context, update) {
          return Padding(
            padding: EdgeInsets.only(
              right: getScreenWidth(30),
              left: getScreenWidth(30),
              top: getScreenHeight(45),
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                CupertinoButton(
                  minSize: 0,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.topLeft,
                  child: const Icon(
                    Icons.close_sharp,
                    color: Color(0xFF1D232E),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: getScreenHeight(27)),
                InputField(
                  hint: 'Search for a country',
                  controller: searchController,
                  label: '',
                  autofocus: false,
                  prefix: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getScreenWidth(12),
                    ),
                    child: Icon(
                      Icons.search,
                      size: getScreenHeight(25),
                      color: const Color(0xFFDADADA),
                    ),
                  ),
                  onChanged: (value) {
                    final val = value.toUpperCase();

                    if (value.isNotEmpty) {
                      filteredCodes = codes
                          .where((e) =>
                              e.code!.contains(val) ||
                              e.dialCode!.contains(val) ||
                              e.name!.toUpperCase().contains(val))
                          .toList();
                      if (filteredCodes.isEmpty) filteredCodes = codes;
                      update(() {});
                    }
                  },
                ),
                SizedBox(
                  height: getScreenHeight(500),
                  child: ScrollConfiguration(
                    behavior: CustomScrollBehavior(),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: getScreenHeight(15)),
                      itemCount: filteredCodes.length,
                      itemBuilder: (context, index) {
                        final data = filteredCodes[index];
                        return CupertinoButton(
                          onPressed: () {
                            onChanged(data);
                            Navigator.pop(context);
                          },
                          minSize: 0,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            dense: true,
                            minLeadingWidth: getScreenWidth(18),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: getScreenHeight(3),
                            ),
                            leading: Container(
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  getScreenHeight(2),
                                ),
                              ),
                              child: Image.asset(
                                data.flagUri!,
                                package: 'country_code_picker',
                                width: getScreenWidth(24),
                              ),
                            ),
                            title: Text(
                              data.name ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: getScreenHeight(16),
                                  color: const Color(0xFF1C1C1E)),
                            ),
                            trailing: Text(
                              data.dialCode ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: getScreenHeight(16),
                                  color: const Color(0xFF1C1C1E)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
          );
        });
      });
}
