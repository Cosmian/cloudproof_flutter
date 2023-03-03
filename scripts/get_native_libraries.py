# -*- coding: utf-8 -*-
import os
import shutil
import ssl
import urllib.request
import zipfile
from os import path, remove, system


CLOUDPROOF_RUST_VERSION = 'v0.1.0'


def files_to_be_copied(name: str) -> dict[str, str]:
    jni_libs = 'android/src/main/jniLibs'
    return {
        f'tmp/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/{name}.h': f'resources/{name}.h',
        f'tmp/x86_64-apple-darwin/x86_64-apple-darwin/release/libcloudproof_{name}.dylib': f'resources/libcloudproof_{name}.dylib',
        f'tmp/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release/libcloudproof_{name}.so': f'resources/libcloudproof_{name}.so',
        f'tmp/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release/cloudproof_{name}.dll': f'resources/cloudproof_{name}.dll',
        f'tmp/android/armeabi-v7a/libcloudproof_{name}.so': f'{jni_libs}/armeabi-v7a/libcloudproof_{name}.so',
        f'tmp/android/arm64-v8a/libcloudproof_{name}.so': f'{jni_libs}/arm64-v8a/libcloudproof_{name}.so',
        f'tmp/android/x86/libcloudproof_{name}.so': f'{jni_libs}/x86/libcloudproof_{name}.so',
        f'tmp/android/x86_64/libcloudproof_{name}.so': f'{jni_libs}/x86_64/libcloudproof_{name}.so',
        f'tmp/x86_64-apple-darwin/universal/release/libcloudproof_{name}.a': f'ios/libcloudproof_{name}.a',
    }


def download_native_libraries(name: str, version: str) -> bool:
    ssl._create_default_https_context = ssl._create_unverified_context

    findex_files = files_to_be_copied('findex')
    cover_crypt_files = files_to_be_copied('cover_crypt')
    to_be_copied = findex_files | cover_crypt_files

    missing_files = False
    for key in to_be_copied:
        if not path.exists(to_be_copied[key]):
            missing_files = True
            break

    if missing_files:

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
                        print(f'Copied OK: {to_be_copied[key]}...')

                    shutil.rmtree('tmp')

                system('flutter pub run ffigen --config ffigen_cover_crypt.yaml')
                system('flutter pub run ffigen --config ffigen_findex.yaml')
                remove('all.zip')
        except Exception as e:
            print(f'Cannot get {name} {version} ({e})')
            return False
    return True


if __name__ == '__main__':
    ret = download_native_libraries('cloudproof_rust', CLOUDPROOF_RUST_VERSION)
    if ret is False and os.getenv('GITHUB_ACTIONS'):
        download_native_libraries('cloudproof_rust', 'last_build')
