const fs=require('fs');fs.mkdirSync('dist',{recursive:true});
fs.copyFileSync('src/index.html','dist/index.html');console.log('frontend built with node',process.version);
