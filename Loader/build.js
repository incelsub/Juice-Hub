const crypto = require('crypto');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const luamin = require('luamin.ts');
const { optimize } = require('optimize.lua');

// https://stackoverflow.com/questions/5827612/node-js-fs-readdir-recursive-directory-search
const walk = dir => {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = dir + '/' + file;
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      /* Recurse into a subdirectory */
      results = results.concat(walk(file));
    } else {
      /* Is a file */
      results.push(file);
    }
  });
  return results;
};

// Get all files, and add them to a list as arguments
const files = walk(path.resolve(__filename, '..', 'src'));
const outFile = path.resolve(__filename, '..', 'Rewrite.tmp-1.lua');
let arguments = '-o ' + path.relative(process.cwd(), outFile) + '';
arguments +=
  ' ' +
  path.relative(process.cwd(), path.resolve(__filename, '..', 'src', 'index')) +
  '';
for (const index in files) {
  if (Object.hasOwnProperty.call(files, index)) {
    const filePath = path
      .relative(process.cwd(), files[index])
      .replace('.lua', '');
    if (filePath !== 'src\\index' && filePath !== 'src/index') {
      arguments += ' ' + filePath.replace(/\\/g, '/') + '';
    }
  }
}

const command = `"${path.resolve(
  __filename,
  '..',
  'buildDeps',
  'luacc.lua',
)}" ${arguments}`;
if (process.platform === 'win32') {
  fs.writeFileSync(
    'build.bat',
    `"${path.resolve(
      __filename,
      '..',
      'buildDeps',
      'lua',
      'win32',
      'lua53',
    )}" ${command}`,
  );
  execSync(path.resolve('build.bat'));
  fs.rmSync('build.bat');
} else {
  fs.writeFileSync(
    'build.sh',
    `#!/bin/bash
luajit ${command}`,
  ); //assume luajit is installed fuck off
  execSync('build.sh');
  fs.rmSync('build.sh');
}
const output = //optimize(
  `------ https://github.com/Conglomeration/Lua/blob/main/dist/combine-fixtmp.js
-- localize globals
local require = require;
local math = math;
local bit = bit or bit32;
local error = error;
local table = table;
local string = string;
local pairs = pairs;
local setmetatable = setmetatable;
local print = print;
local tonumber = tonumber;
local ipairs = ipairs;
local getfenv = getfenv;
local getgenv = getgenv;
-- general polyfill
local fenv = (getfenv or function()return _ENV end)();
local package = --[[fenv.package or]] {["searchers"]={[2]=function(p) error("Module not bundled: "..p) end}}
if _VERSION == "Luau" then
  require = (function(...) return package["searchers"][2](...)() end);
  math = setmetatable({["mod"]=math.fmod},{__index=fenv.math})
end;
` + fs.readFileSync(outFile, 'utf-8').replace(/src\//g, '');
//);
fs.rmSync(outFile);
let final = luamin
  .Minify(output, {
    SolveMath: true,
    RenameGlobals: false,
    RenameVariables: true,
  })
  .replace(/endlocal/g, 'end;local')
  .replace(/1do/g, '1 do');
final = final.replace(
  /\#\#\#hash\#\#\#/g,
  crypto.createHash('sha256').update(final).digest('hex'),
);
fs.writeFileSync(path.resolve(outFile, '..', 'dist', 'out.lua'), final);
// not stolen from YieldingCoder#3961 nope nope nope
