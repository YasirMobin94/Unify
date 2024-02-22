import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';

List<Map<String, String>> coursesData = [];

class StudyViewSpace extends StatefulWidget {
  const StudyViewSpace({super.key});

  @override
  State<StudyViewSpace> createState() => _StudyViewSpaceState();
}

class _StudyViewSpaceState extends State<StudyViewSpace> {
  final bool _isLoading = false;
  List<dynamic> courses = [];
  List<dynamic> courcesMemberTabLink = [];
  InAppWebViewController? _webViewController;
  bool start1 = false;
  bool start2 = false;
  bool start3 = false;
  bool start = false;
  bool got1 = false;
  bool got3 = false;
  bool scrapNamesOfMember = false;
  bool scrapNames = false;
  bool showList = false;
  List<String> urlsToLoad = [];
  List<String> urlsToLoadForNames = [];
  int currentUrlIndex = 0;

  void showLongDurationSnackbar(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 20,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: "#000000",
      webShowClose: true,
    );
  }

  void showCustomSnackbarLong(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 20,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: "#000000",
      webShowClose: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 28.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(
                      CupertinoIcons.back,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    "All spaces",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          body: scrapNamesOfMember
              ? InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: Uri.tryParse(
                      'https://login.hs-heilbronn.de/realms/hhn/protocol/openid-connect/auth?response_mode=form_post&response_type=id_token&redirect_uri=https%3A%2F%2Filias.hs-heilbronn.de%2Fopenidconnect.php&client_id=hhn_common_ilias&nonce=badc63032679bb541ff44ea53eeccb4e&state=2182e131aa3ed4442387157cd1823be0&scope=openid+openid',
                    ),
                  ),
                  onLoadStart: (controller, url) {
                    setState(() {
                      _webViewController = controller;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    if (url.toString() ==
                        "https://ilias.hs-heilbronn.de/ilias.php?baseClass=ilDashboardGUI&cmd=jumpToSelectedItems") {
                      for (final data in urlsToLoadForNames) {
                        log("Url: $data");
                        await controller.loadUrl(
                          urlRequest: URLRequest(
                            url: Uri.parse(data),
                          ),
                        );
                        await Future.delayed(
                          const Duration(
                            seconds: 3,
                          ),
                        );
                        // final memberTabHref =
                        //     await controller.evaluateJavascript(
                        //   source: '''
                        //                 (() => {
                        //                 const membersTab = document.querySelector('#tab_members a');
                        //                 return membersTab ? membersTab.getAttribute('href') : '';
                        //                 })()
                        //                 ''',
                        // );

                        // courcesMemberTabLink.add({
                        //   'memberPageUrl':
                        //       "https://ilias.hs-heilbronn.de/" + memberTabHref,
                        // });
                      }
                      setState(() {
                        scrapNamesOfMember = false;
                        showList = true;
                      });
                    }
                  },
                )
              : showList
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 15.0),
                          child: Text(
                            "Your courses",
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: courses.length,
                            itemBuilder: (context, index) {
                              final data = courses[index];
                              return ListTile(
                                trailing: const Icon(CupertinoIcons.forward),
                                leading: CircleAvatar(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    71,
                                    24,
                                    201,
                                  ),
                                  child: Text(
                                    data['refId'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                                title: Text(data['name']),
                                onTap: () {},
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : start && !got1
                      ? start2 && !start1
                          ? InAppWebView(
                              initialUrlRequest: URLRequest(
                                url: Uri.tryParse(
                                  'https://login.hs-heilbronn.de/realms/hhn/protocol/openid-connect/auth?response_mode=form_post&response_type=id_token&redirect_uri=https%3A%2F%2Filias.hs-heilbronn.de%2Fopenidconnect.php&client_id=hhn_common_ilias&nonce=badc63032679bb541ff44ea53eeccb4e&state=2182e131aa3ed4442387157cd1823be0&scope=openid+openid',
                                ),
                              ),
                              onLoadStart: (controller, url) {
                                setState(() {
                                  _webViewController = controller;
                                });
                              },
                              onLoadStop: (controller, url) async {
                                if (url.toString() ==
                                    "https://ilias.hs-heilbronn.de/ilias.php?baseClass=ilDashboardGUI&cmd=jumpToSelectedItems") {
                                  for (final data in urlsToLoad) {
                                    await controller.loadUrl(
                                      urlRequest: URLRequest(
                                        url: Uri.parse(data),
                                      ),
                                    );
                                    await Future.delayed(
                                      const Duration(
                                        seconds: 3,
                                      ),
                                    );
                                    final memberTabHref =
                                        await controller.evaluateJavascript(
                                      source: '''
                                        (() => {
                                        const membersTab = document.querySelector('#tab_members a');
                                        return membersTab ? membersTab.getAttribute('href') : '';
                                        })()
                                        ''',
                                    );

                                    courcesMemberTabLink.add({
                                      'memberPageUrl':
                                          "https://ilias.hs-heilbronn.de/" +
                                              memberTabHref,
                                    });
                                  }
                                  setState(() {
                                    start2 = true;
                                    start1 = false;
                                    got3 = true;
                                    start = false;
                                  });
                                }
                              },
                            )
                          : InAppWebView(
                              initialUrlRequest: URLRequest(
                                url: Uri.tryParse(
                                  'https://login.hs-heilbronn.de/realms/hhn/protocol/openid-connect/auth?response_mode=form_post&response_type=id_token&redirect_uri=https%3A%2F%2Filias.hs-heilbronn.de%2Fopenidconnect.php&client_id=hhn_common_ilias&nonce=badc63032679bb541ff44ea53eeccb4e&state=2182e131aa3ed4442387157cd1823be0&scope=openid+openid',
                                ),
                              ),
                              onLoadStart: (controller, url) {
                                setState(() {
                                  _webViewController = controller;
                                });
                              },
                              onLoadStop: (controller, url) async {
                                if (url.toString() ==
                                    "https://ilias.hs-heilbronn.de/ilias.php?baseClass=ilDashboardGUI&cmd=jumpToSelectedItems") {
                                  controller.loadUrl(
                                    urlRequest: URLRequest(
                                      url: Uri.parse(
                                        "https://ilias.hs-heilbronn.de/ilias.php?cmdClass=ilmembershipoverviewgui&cmdNode=jx&baseClass=ilmembershipoverviewgui",
                                      ),
                                    ),
                                  );
                                  await Future.delayed(
                                      const Duration(seconds: 2), () async {
                                    final result =
                                        await controller.evaluateJavascript(
                                      source: '''
                               const courseRows = document.querySelectorAll('.il-std-item');
                               const courses = [];

                              function getRefId(url) {
                              const match = url.match(/ref_id=(\\d+)/);
                              return match ? match[1] : '';
                              }

                              courseRows.forEach((courseRow) => {
                              const imgElement = courseRow.querySelector('img.icon');
                              if (imgElement && imgElement.getAttribute('alt') !== 'Symbol Gruppe') {
                              const courseNameElement = courseRow.querySelector('.il-item-title a');
                              if (courseNameElement) {
                              const courseName = courseNameElement.innerText;
                              const courseUrl = courseNameElement.getAttribute('href');
                              const courseRefId = getRefId(courseUrl);
                              courses.push({
                              'name': courseName,
                              'refId': courseRefId,
                              'url': courseUrl,
                              });
                              }
                              }
                              });
                              courses;
                              ''',
                                    );

                                    setState(() {
                                      courses = result;
                                      start2 = true;
                                      start1 = false;
                                    });
                                    for (final name in courses) {
                                      coursesData.add({
                                        'name': name['name'],
                                        'refId': name['refId'],
                                        'courseUrl':
                                            "https://ilias.hs-heilbronn.de/" +
                                                name["url"],
                                      });
                                    }
                                  });
                                  setState(() {
                                    start2 = true;
                                    start1 = false;
                                    got1 = true;
                                    start = false;
                                  });
                                }
                              },
                            )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("Courses not synchronized"),
                              const SizedBox(
                                height: 20,
                              ),
                              ElevatedButton(
                                onPressed: got1
                                    ? () async {
                                        for (final e in coursesData) {
                                          urlsToLoad.add(e["courseUrl"]!);
                                        }

                                        await Future.delayed(
                                          const Duration(seconds: 1),
                                        );
                                        setState(() {
                                          start1 = false;
                                          start = true;
                                          start2 = true;
                                          got1 = false;
                                        });
                                        showCustomSnackbarLong(
                                          context,
                                          "Please wait while fetch data from the server",
                                        );
                                      }
                                    : got3
                                        ? () async {
                                            for (final e
                                                in courcesMemberTabLink) {
                                              urlsToLoadForNames
                                                  .add(e["memberPageUrl"]);
                                            }

                                            await Future.delayed(
                                              const Duration(seconds: 1),
                                            );
                                            setState(() {
                                              scrapNamesOfMember = true;
                                            });
                                            showCustomSnackbarLong(
                                              context,
                                              "Please wait while fetch data from the server",
                                            );
                                          }
                                        : () async {
                                            setState(() {
                                              start1 = true;
                                              start = true;
                                              start2 = false;
                                            });
                                            showCustomSnackbarLong(
                                              context,
                                              "Please wait while fetch data from the server",
                                            );
                                          },
                                child: got1
                                    ? const Text("Synchronize Students")
                                    : got3
                                        ? const Text("Synchronize Emails")
                                        : const Text("Synchronize"),
                              ),
                            ],
                          ),
                        ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: SizedBox(
                height: 50,
                child: Lottie.asset(
                  "assets/loading.json",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
