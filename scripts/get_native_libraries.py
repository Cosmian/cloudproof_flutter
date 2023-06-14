# -*- coding: utf-8 -*-
import os
import shutil
import ssl
import urllib.request
import zipfile
from os import path, remove, system


def files_to_be_copied(name: str):
    """
    Get the list of files to be copied
    """
    jni_libs = 'android/src/main/jniLibs'
    return {
        f'tmp/x86_64-apple-darwin/{name}.h': f'resources/{name}.h',
        f'tmp/x86_64-apple-darwin/{name}.h': f'example/ios/{name}.h',
        f'tmp/x86_64-apple-darwin/x86_64-apple-darwin/release/libcosmian_{name}.dylib': f'resources/libcosmian_{name}.dylib',
        f'tmp/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release/libcosmian_{name}.so': f'resources/libcosmian_{name}.so',
        f'tmp/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release/cosmian_{name}.dll': f'resources/cosmian_{name}.dll',
        f'tmp/android/armeabi-v7a/libcosmian_{name}.so': f'{jni_libs}/armeabi-v7a/libcosmian_{name}.so',
        f'tmp/android/arm64-v8a/libcosmian_{name}.so': f'{jni_libs}/arm64-v8a/libcosmian_{name}.so',
        f'tmp/android/x86/libcosmian_{name}.so': f'{jni_libs}/x86/libcosmian_{name}.so',
        f'tmp/android/x86_64/libcosmian_{name}.so': f'{jni_libs}/x86_64/libcosmian_{name}.so',
        f'tmp/x86_64-apple-darwin/universal/release/libcosmian_{name}.a': f'ios/libcosmian_{name}.a',
        f'tmp/x86_64-apple-darwin/universal/release/libcosmian_{name}.a': f'example/ios/libcosmian_{name}.a',
    }


def write_ios_cloudproof_plugin_header():
    """
    Automatically write the ios cloudproof header
    """
    # Write ios header
    cloudproof_plugin_header = """#import <Flutter/Flutter.h>

@interface CloudproofPlugin : NSObject<FlutterPlugin>
@end
"""
    if not os.path.exists('resources/findex.h') or not os.path.exists(
        'resources/cover_crypt.h'
    ):
        raise Exception('missing header file (findex.h or cover_crypt.h)')

    with open(
        'ios/Classes/CloudproofPlugin.h', 'w', encoding='utf-8'
    ) as cloudproof_plugin_header_file:
        cloudproof_plugin_header_file.write(cloudproof_plugin_header)
        with open(
            'resources/cover_crypt.h', 'r', encoding='utf-8'
        ) as cover_crypt_header:
            file_content = (
                cover_crypt_header.read()
            )  # Read whole file in file_content
            cloudproof_plugin_header_file.write(file_content)
            cloudproof_plugin_header_file.write('\n')
        with open(
            'resources/findex.h', 'r', encoding='utf-8'
        ) as findex_header:
            file_content = (
                findex_header.read()
            )  # Read whole file in file_content
            cloudproof_plugin_header_file.write(file_content)
            cloudproof_plugin_header_file.write('\n')
    print('Generate CloudproofPlugin.h done!')


def download_native_libraries(name: str, version: str) -> bool:
    """Download and extract native libraries"""
    ssl._create_default_https_context = ssl._create_unverified_context

    to_be_copied = files_to_be_copied(name)

    missing_files = False
    for key, value in to_be_copied.items():
        if not path.exists(value):
            missing_files = True
            break

    if missing_files:
        url = f'https://package.cosmian.com/{name}/{version}/all.zip'
        try:
            with urllib.request.urlopen(url) as request:
                if request.getcode() != 200:
                    print(
                        f'Cannot get {name} {version} \
                         ({request.getcode()})'
                    )
                else:
                    print(f'Getting {name} {version}')
                    if path.exists('tmp'):
                        shutil.rmtree('tmp')
                    if path.exists('all.zip'):
                        remove('all.zip')

                    open('all.zip', 'wb').write(request.read())
                    with zipfile.ZipFile('all.zip', 'r') as zip_ref:
                        zip_ref.extractall('tmp')
                        for key, value in to_be_copied.items():
                            shutil.copyfile(key, value)
                            print(f'Copied OK: {value}...')

                        shutil.rmtree('tmp')

                    system('flutter pub get')
                    system(
                        f'flutter pub run ffigen --config ffigen_{name}.yaml'
                    )

                    remove('all.zip')
        # pylint: disable=broad-except
        except Exception as exception:
            print(f'Cannot get {name} {version} ({exception})')
            return False
    return True


if __name__ == '__main__':
    ret = download_native_libraries('findex', 'v2.0.5')
    if ret is False and os.getenv('GITHUB_ACTIONS'):
        download_native_libraries('findex', 'last_build')
    ret = download_native_libraries('cover_crypt', 'v8.0.2')
    if ret is False and os.getenv('GITHUB_ACTIONS'):
        download_native_libraries('cover_crypt', 'last_build')
    # write_ios_cloudproof_plugin_header()
