#!/usr/bin/env python3
"""Preview or copy selected dotfiles, with per-file backups; no sudo or reload."""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import sys

ROOT=Path(__file__).resolve().parent

def entries():
    for source in sorted((ROOT/'config').rglob('*')):
        if source.is_file():
            relative=source.relative_to(ROOT/'config')
            yield relative.parts[0],source,Path('.config')/relative
    for source in sorted((ROOT/'scripts').glob('*')):
        if source.is_file():yield 'scripts',source,Path('.local/bin')/source.name
    for source in sorted((ROOT/'plugins').rglob('*')):
        if source.is_file():yield 'plugins',source,Path('.local/share/noctalia/plugins')/source.relative_to(ROOT/'plugins')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true',help='Actually copy files; otherwise preview only')
    parser.add_argument('--component',action='append',help='Select a component; repeat for several, or use all')
    parser.add_argument('--home',type=Path,default=Path.home(),help='Destination home (useful for a staging/test directory)')
    args=parser.parse_args()
    home=args.home.expanduser().absolute()
    available={name for name,_,_ in entries()}
    chosen=set(args.component or (available-{'autostart'}))
    if 'all' in chosen:chosen=available
    if chosen-available:parser.error('Unknown component(s): '+', '.join(sorted(chosen-available)))
    selected=[(source,relative) for name,source,relative in entries() if name in chosen]
    # Validate all paths/templates before making any copies.
    for source,relative in selected:
        if relative.is_absolute() or '..' in relative.parts:raise RuntimeError('Invalid destination path')
        source.read_text()
        destination=home/relative
        # A directory symlink could redirect writes outside the requested home.
        for parent in destination.parents:
            if parent==home:break
            if parent.is_symlink():raise RuntimeError('Parent directory is a symlink: '+str(parent))
        if destination.exists() and destination.is_dir():raise RuntimeError('Destination is a directory: '+str(destination))
    if not args.apply:
        print('Preview only. No files changed. Add --apply to copy these files.')
        for _,relative in selected:print(home/relative)
        print('Components:',', '.join(sorted(chosen)))
        print('Autostart definitions are opt-in: --component autostart')
        return 0
    stamp=datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup=home/'.local/state/dotfiles-backups'/stamp
    backup.mkdir(parents=True,exist_ok=False)
    changes=[]
    for source,relative in selected:
        destination=home/relative
        previous=backup/relative
        existed=destination.exists() or destination.is_symlink()
        if existed:
            previous.parent.mkdir(parents=True,exist_ok=True)
            if destination.is_symlink():previous.symlink_to(os.readlink(destination))
            else:shutil.copy2(destination,previous)
        destination.parent.mkdir(parents=True,exist_ok=True)
        text=source.read_text().replace('@HOME@',str(home))
        temporary=destination.with_name(destination.name+'.dotfiles-tmp')
        with temporary.open('x') as stream:stream.write(text)
        temporary.chmod(0o755 if relative.parts[:2]==('.local','bin') else source.stat().st_mode & 0o777)
        temporary.replace(destination)
        changes.append({'destination':str(relative),'had_previous_file':existed})
    (backup/'manifest.json').write_text(json.dumps(changes,indent=2)+'\n')
    print('Copied',len(changes),'files. Backup:',backup)
    print('Nothing was launched, enabled or reloaded. Review your monitor names and app commands before reloading.')
    return 0

if __name__=='__main__':
    try:sys.exit(main())
    except (OSError,RuntimeError,ValueError) as error:
        print('Dotfiles installer:',error,file=sys.stderr);sys.exit(1)
