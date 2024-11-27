1. 下载一些`yomitan`/`yomichan`词典到`/database_build/jisho`
2. 下载`kanji-frequency-master`到`/database_build/jisho`
3. 解包得到`arujisho.db.zip`
4. `sudachidict.zip`(https://github.com/WorksApplications/SudachiDict/releases/tag/v20241021)
5. update `sudachi.rs`
6. 处理flutter依赖
7. 配置`ANDROID_NDK_HOME`
8. `rustup target add x86_64-linux-android`
9. `rustup target add armv7-linux-androideabi`
10. `rustup target install aarch64-linux-android`
11. `cargo install cargo-ndk`
12. `dart run build_runner build`
13. `flutter build apk --release`