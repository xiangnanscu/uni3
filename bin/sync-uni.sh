#!/bin/bash

xodel_dirs=('src/views')
sync_dirs=('bin' 'patches' 'template' 'components' 'composables' 'globals' 'lib' 'src/components' 'src/composables' 'src/lib'  )
down_dirs=("${xodel_dirs[@]}" "${sync_dirs[@]}")
skip_files=('Home.vue' 'wx_verify.lua' 'init-certbot.sh.ejs' 'init-certbot.sh' 'index.ts' 'tabbar')
top_files=('.eslintrc.cjs' 'tsconfig.json' 'tsconfig.node.json' 'vite.config.ts')
working_dir=$PWD
lib_dir="$working_dir/tmp/template"

function get_repo() {
  rm -rf tmp
  while true; do timeout 15 gh repo clone xnscu/create-uni tmp -- --depth=1 && break; done
}

function main() {
  if [[ ${1:-download} == download ]]; then
    get_repo
    src_dir="$lib_dir"
    dest_dir="$working_dir"
    echo "sync from $src_dir to $dest_dir"
    if [ ! -d "$dest_dir" ]; then
      mkdir -p "$dest_dir"
    fi
    for tf in "${top_files[@]}"; do
      cp -rf "$src_dir/$tf" "$dest_dir"
      echo "复制$src_dir/$tf到$dest_dir"
    done
    for dir in "${down_dirs[@]}"; do
      echo "处理 $dir"
      if [[ "$dir" != "src/views" ]]; then
        rm -rf "$dest_dir/$dir"
      fi
      if [ ! -d "$dest_dir/$dir" ]; then
        mkdir -p "$dest_dir/$dir"
      fi
      for file in $src_dir/$dir/*; do
        fn="$(basename $file)"
        skip=0
        for sfn in "${skip_files[@]}"; do
          if [[ $fn == $sfn ]]; then
            skip=1
            break
          fi
        done
        if [[ $skip == 1 ]]; then
          echo "跳过$file"
          continue
        fi
        cp -rf "$file" "$dest_dir/$dir"
        echo "复制$file到$dest_dir/$dir"
      done
    done
    rm -rf tmp
  elif [[ $1 == "preview" ]]; then
    rm -rf tmp/
    get_repo
    src_dir="$working_dir"
    dest_dir="$lib_dir"
    mkdir -p "$dest_dir"
    echo "sync from $src_dir to $dest_dir"
    for tf in "${top_files[@]}"; do
      cp -rf "$src_dir/$tf" "$dest_dir"
      echo "复制$src_dir/$tf到$dest_dir"
    done
    for dir in "${xodel_dirs[@]}"; do
      echo "处理 $dir"
      rm -rf "$dest_dir/$dir"
      for file in $src_dir/$dir/*; do
        fn="$(basename $file)"
        lib_file="$dest_dir/$dir/$fn"
        skip=0
        for sfn in "${skip_files[@]}"; do
          if [[ $fn == $sfn ]]; then
            skip=1
            break
          fi
        done
        if [[ $skip == 1 ]]; then
          echo "跳过$file"
          continue
        fi
        if [ -f "$lib_file" ]; then
          mkdir -p "$dest_dir/$dir"
          cp -rf "$file" "$dest_dir/$dir"
          echo "复制$file到$dest_dir/$dir"
        fi
      done
    done
    for dir in "${sync_dirs[@]}"; do
      echo "处理 $dir"
      rm -rf "$dest_dir/$dir"
      for file in $src_dir/$dir/*; do
        fn="$(basename $file)"
        skip=0
        for sfn in "${skip_files[@]}"; do
          if [[ $fn == $sfn ]]; then
            skip=1
            break
          fi
        done
        if [[ $skip == 1 ]]; then
          echo "跳过$file"
          continue
        fi
        mkdir -p "$dest_dir/$dir"
        cp -rf "$file" "$dest_dir/$dir"
        echo "复制$file到$dest_dir/$dir"
      done
    done
    code tmp
  elif [[ $1 == upload ]]; then
    if [ ! -d tmp/ ]; then
      echo "no tmp download..."
      main "preview"
    fi
    if [ -d tmp/ ]; then
      cd tmp
      git add . && git commit -am 'sync-xodel'
      while true; do timeout 15 git push origin master && break; done
      cd ..
      rm -rf tmp
      echo 'github同步完成'
    fi
  else
    echo "invalid argument: $1"
  fi
}

main $1