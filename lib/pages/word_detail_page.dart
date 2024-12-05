import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:icofont_flutter/icofont_flutter.dart';

class WordDetailPage extends StatefulWidget {
  final String wordTitle;
  final String originWord;
  final List<Widget> details;
  final int freqRank;
  final String yomikata;
  // 在数据库中的条目数，用来当缓存键
  final int idex;

  const WordDetailPage(
      {super.key,
      required this.wordTitle,
      required this.details,
      required this.freqRank,
      required this.yomikata,
      required this.originWord,
      required this.idex});

  @override
  State<WordDetailPage> createState() {
    return WordDetailState();
  }
}

class WordDetailState extends State<WordDetailPage> {
  late FlutterTts tts;

  @override
  void initState() {
    super.initState();
    tts = FlutterTts();
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false, // 初始高度不覆盖整个屏幕
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(children: [
                    Expanded(
                      flex: 20,
                      child: Text(
                        widget.wordTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.fade, // 显示溢出的内容（会换行）
                      ),
                    ),
                    const Spacer(),
                    Text((widget.freqRank + 1).toString()),
                    IconButton(
                      icon: const Icon(IcoFontIcons.soundWaveAlt),
                      onPressed: () async {
                        if(await tts.isLanguageAvailable("ja-JP")){
                          await tts.setLanguage("ja-JP");
                        }
                        else {
                          if(context.mounted){
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('日本語のTTSが見つかりませんでした'),
                                showCloseIcon: true,
                              ),
                            );
                          }
                        }
                        await tts.awaitSpeakCompletion(true);
                        await tts.speak(widget.originWord);
                      },
                    ),
                    // FutureBuilder(
                    //     future: Provider.of<TtsCacheProvider>(context).hatsuon(
                    //         word: widget.originWord,
                    //         idex: widget.idex,
                    //         yomikata: widget.yomikata),
                    //     builder: (context, AsyncSnapshot<Uri?> snapshot) {
                    //       Widget content;
                    //       if (snapshot.hasData) {
                    //         if (snapshot.data == null) {
                    //           content = const Icon(Icons.error_sharp);
                    //         } else {
                    //           content = IconButton(
                    //             icon: const Icon(IcoFontIcons.soundWaveAlt),
                    //             onPressed: () async {
                    //                 try {
                    //                   final player = AudioPlayer();
                    //                   // final session =
                    //                   //     await AudioSession.instance;
                    //                   // await initAudioService(session);
                    //                   // await player.setFilePath(res.path);
                    //                   // logger.d(
                    //                   //     "sessionisConfigured: ${session.isConfigured}");
                    //                   // final audioSource = LockCachingAudioSource(snapshot.data!);
                    //                   player.setAudioSource(AudioSource.uri(snapshot.data!));
                    //                   // await player.play();
                    //                   player.play();
                    //                   logger.d("end playing hatsuon");
                    //                   // if (await session.setActive(true)) {
                    //                   //   logger.d("start playing hatsuon");
                    //                   //   await player.play();
                    //                   //   await session.setActive(false);
                    //                   //   logger.d("end playing hatsuon");
                    //                   // }
                    //                 } catch (e) {
                    //                   logger.e(e.toString());
                    //                 }
                    //             },
                    //           );
                    //         }
                    //       } else if (snapshot.hasError) {
                    //         content = const Icon(Icons.error_outline);
                    //       } else {
                    //         content = const CircularProgressIndicator();
                    //       }

                    //       return Container(
                    //           padding: const EdgeInsets.all(4.0),
                    //           width: 45.0,
                    //           child: content);
                    //     })
                  ]),
                ),
                const SizedBox(height: 16),
                ...widget.details
              ],
            ),
          ),
        );
      },
    );
  }
}
