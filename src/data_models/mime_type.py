# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

types = {
    "c": "text/x-c",
    "cpp": "text/x-c++",
    "cs": "text/x-csharp",
    "css": "text/css",
    "csv": "text/csv",
    "doc": "application/msword",
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "gif": "image/gif",
    "go": "text/x-golang",
    "html": "text/html",
    "java": "text/x-java",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "js": "text/javascript",
    "json": "application/json",
    "md": "text/markdown",
    "pdf": "application/pdf",
    "php": "text/x-php",
    "png": "image/png",
    "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "py": "text/x-python",
    "py": "text/x-script.python",
    "rb": "text/x-ruby",
    "sh": "application/x-sh",
    "tex": "text/x-tex",
    "ts": "application/typescript",
    "txt": "text/plain",
    "webp": "image/webp",
    "xls": "application/vnd.ms-excel",
    "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
}


def mime_type(filename):
    ext = filename.split('.').pop()
    return types[ext] or "application/octet-stream"
