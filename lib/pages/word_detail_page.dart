import 'package:arujisho/providers/tts_cache_provider.dart';
import 'package:arujisho/utils/audio_util.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:icofont_flutter/icofont_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

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
  late AudioPlayer player;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logger = Provider.of<Logger>(context);
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
                    FutureBuilder(
                        future: Provider.of<TtsCacheProvider>(context).hatsuon(
                            word: widget.originWord,
                            idex: widget.idex,
                            yomikata: widget.yomikata),
                        builder: (context, AsyncSnapshot<String?> snapshot) {
                          Widget content;
                          if (snapshot.hasData) {
                            content = IconButton(
                              icon: snapshot.data == null
                                  ? const Icon(Icons.error_outline)
                                  : const Icon(IcoFontIcons.soundWaveAlt),
                              onPressed: () async {
                                if (snapshot.data != null) {
                                  DefaultCacheManager()
                                      .getSingleFile(snapshot.data!,
                                          headers: burpHeader)
                                      .then((res) async {
                                    try {
                                      final session =
                                          await AudioSession.instance;
                                      await initAudioService(session);
                                      await player.setFilePath(res.path);
                                      logger.d(
                                          "sessionisConfigured: ${session.isConfigured}");
                                      await player.play();
                                      logger.d("end playing hatsuon");
                                      // if (await session.setActive(true)) {
                                      //   logger.d("start playing hatsuon");
                                      //   await player.play();
                                      //   await session.setActive(false);
                                      //   logger.d("end playing hatsuon");
                                      // }
                                    } catch (e) {
                                      logger.d(e);
                                    }
                                  });
                                }
                              },
                            );
                          } else {
                            content = const CircularProgressIndicator();
                          }
                          return Container(
                              padding: const EdgeInsets.all(4.0),
                              width: 45.0,
                              child: content);
                        })
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
