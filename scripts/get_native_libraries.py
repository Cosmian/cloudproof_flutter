# -*- coding: utf-8 -*-
import os
import shutil
import ssl
import urllib.request
import zipfile
from os import path, remove, system


def files_to_be_copied():
    """
    Get the list of files to be copied
    """
    jni_libs = 'android/src/main/jniLibs'
    return {
        'tmp/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/cloudproof.h': 'resources/cloudproof.h',
        'tmp/x86_64-apple-darwin/x86_64-apple-darwin/release/libcloudproof.dylib': 'resources/libcloudproof.dylib',
        'tmp/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release/libcloudproof.so': 'resources/libcloudproof.so',
        'tmp/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release/cloudproof.dll': 'resources/cloudproof.dll',
        'tmp/android/armeabi-v7a/libcloudproof.so': f'{jni_libs}/armeabi-v7a/libcloudproof.so',
        'tmp/android/arm64-v8a/libcloudproof.so': f'{jni_libs}/arm64-v8a/libcloudproof.so',
        'tmp/android/x86/libcloudproof.so': f'{jni_libs}/x86/libcloudproof.so',
        'tmp/android/x86_64/libcloudproof.so': f'{jni_libs}/x86_64/libcloudproof.so',
        'tmp/x86_64-apple-darwin/universal/release/libcloudproof.a': 'ios/libcloudproof.a',
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
    with open(
        'ios/Classes/CloudproofPlugin.h', 'w', encoding='utf-8'
    ) as cloudproof_plugin_header_file:
        cloudproof_plugin_header_file.write(cloudproof_plugin_header)
        with open('resources/cloudproof.h', 'r', encoding='utf-8') as cloudproof_header:
            file_content = cloudproof_header.read()  # Read whole file in file_content
            cloudproof_plugin_header_file.write(file_content)
            cloudproof_plugin_header_file.write('\n')


def download_native_libraries(version: str) -> bool:
    """Download and extract native libraries"""
    ssl._create_default_https_context = ssl._create_unverified_context

    to_be_copied = files_to_be_copied()

    missing_files = False
    for key, value in to_be_copied.items():
        if not path.exists(value):
            missing_files = True
            break

    if missing_files:
        url = f'https://package.cosmian.com/cloudproof_rust/{version}/all.zip'
        try:
            with urllib.request.urlopen(url) as request:
                if request.getcode() != 200:
                    print(
                        f'Cannot get cloudproof_rust {version} \
                         ({request.getcode()})'
                    )
                else:
                    print(f'Copying new files from cloudproof_rust {version}')
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
                    system('flutter pub run ffigen --config ffigen_cloudproof.yaml')

                    write_ios_cloudproof_plugin_header()

                    remove('all.zip')
        # pylint: disable=broad-except
        except Exception as exception:
            print(f'Cannot get cloudproof_rust {version} ({exception})')
            return False
    return True


if __name__ == '__main__':
    RET = download_native_libraries('v2.1.0')
    if RET is False and os.getenv('GITHUB_ACTIONS'):
        download_native_libraries('last_build/add_logs_on_findex_callbacks')
    # write_ios_cloudproof_plugin_header()
