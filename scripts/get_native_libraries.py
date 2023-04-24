# -*- coding: utf-8 -*-
import urllib.request
import shutil
import ssl
import zipfile

from os import path, remove, system


def download_native_libraries(name: str, version: str, destination: str):
    ssl._create_default_https_context = ssl._create_unverified_context
    jni_libs = 'android/src/main/jniLibs'

    to_be_copied = {
        f'tmp/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/{name}.h': f'{destination}/{name}.h',
        f'tmp/x86_64-apple-darwin/x86_64-apple-darwin/release/libcosmian_{name}.dylib': f'{destination}/libcosmian_{name}.dylib',
        f'tmp/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release/libcosmian_{name}.so': f'{destination}/libcosmian_{name}.so',
        f'tmp/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release/cosmian_{name}.dll': f'{destination}/cosmian_{name}.dll',
        f'tmp/android/armeabi-v7a/libcosmian_{name}.so': f'{jni_libs}/armeabi-v7a/libcosmian_{name}.so',
        f'tmp/android/arm64-v8a/libcosmian_{name}.so': f'{jni_libs}/arm64-v8a/libcosmian_{name}.so',
        f'tmp/android/x86/libcosmian_{name}.so': f'{jni_libs}/x86/libcosmian_{name}.so',
        f'tmp/android/x86_64/libcosmian_{name}.so': f'{jni_libs}/x86_64/libcosmian_{name}.so',
        f'tmp/x86_64-apple-darwin/universal/release/libcosmian_{name}.a': f'ios/libcosmian_{name}.a',
    }

    missing_files = False
    for key in to_be_copied:
        if not path.exists(to_be_copied[key]):
            missing_files = True
            break

    if missing_files:
        print(
            f'Missing {name} native library. Copy {name} {version} to {destination}...'
        )

        url = f'https://package.cosmian.com/{name}/{version}/all.zip'
        try:
            r = urllib.request.urlopen(url)
            if r.getcode() != 200:
                print(f'Cannot get {name} {version} ({r.getcode()})')
            else:
                if path.exists('tmp'):
                    shutil.rmtree('tmp')
                if path.exists('all.zip'):
                    remove('all.zip')

                open('all.zip', 'wb').write(r.read())
                with zipfile.ZipFile('all.zip', 'r') as zip_ref:
                    zip_ref.extractall('tmp')
                    for key in to_be_copied:
                        shutil.copyfile(key, to_be_copied[key])

                    shutil.rmtree('tmp')

                system(f'flutter pub run ffigen --config ffigen_{name}.yaml')
                remove('all.zip')
        except Exception as e:
            print(f'Cannot get {name} {version} ({e})')
            download_native_libraries(name, 'last_build', destination)


if __name__ == '__main__':
    download_native_libraries('findex', 'v2.0.2', 'resources')
    download_native_libraries('findex', 'last_build', 'resources')
    download_native_libraries('cover_crypt', 'v8.0.2', 'resources')
    download_native_libraries('cover_crypt', 'last_build', 'resources')
