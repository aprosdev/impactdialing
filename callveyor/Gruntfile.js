// Generated on 2014-02-04 using generator-angular 0.7.1
'use strict';

// # Globbing
// for performance reasons we're only matching one level down:
// 'test/spec/{,*/}*.js'
// use this if you want to recursively match all subfolders:
// 'test/spec/**/*.js'

var mountFolder = function (connect, dir) {
    return connect.static(require('path').resolve(dir));
};

module.exports = function (grunt) {

  // Load grunt tasks automatically
  require('load-grunt-tasks')(grunt);

  // Time how long tasks take. Can help when optimizing build times
  require('time-grunt')(grunt);

  // Load bower.json for appMeta info
  var appMeta = grunt.file.readJSON('./bower.json')

  // Define the configuration for all the tasks
  grunt.initConfig({

    // Project settings
    yeoman: {
      // configurable paths
      app: require('./bower.json').appPath || 'app',
      dist: '../public',
      htmlDist: '../app/views/callers/station/'
    },
    // per-env constants
    ngconstant: {
      options: {
        name: 'config',
        dest: 'app/scripts/config.js',
        constants: {
          apiver: 0.1,
          debug: false
        }
      },
      dev: {
        constants: {
          serviceTokens: {
            pusher: '1adc63eef7933def9fa0'
          },
          appMeta: {
            version: appMeta.version,
            stage: 'development'
          },
          debug: true
        }
      },
      dist: {
        constants: {
          serviceTokens: {
            pusher: '6f37f3288a3762e60f94',
            pusherAsia: '9dc7a54f5123dce8c3a5'
          },
          appMeta: {
            version: appMeta.version,
            stage: 'production'
          }
        }
      },
      test: {
        constants: {
          serviceTokens: {
            pusher: 'blah'
          },
          appMeta: {
            version: appMeta.version,
            stage: 'test'
          },
          debug: true
        }
      }
    },
    // Watches files for changes and runs tasks based on the changed files
    watch: {
      coffee: {
        files: ['<%= yeoman.app %>/scripts/**/*.{coffee,litcoffee,coffee.md}'],
        tasks: ['newer:coffee:dist']
      },
      // coffeeTest: {
      //   files: ['test/spec/**/*.{coffee,litcoffee,coffee.md}'],
      //   tasks: ['newer:coffee:test', 'karma']
      // },
      compass: {
        files: ['<%= yeoman.app %>/styles/**/*.{scss,sass}'],
        tasks: ['compass:server', 'autoprefixer']
      },
      gruntfile: {
        files: ['Gruntfile.js']
      },
      ngtemplates: {
        files: ['<%= yeoman.app %>/scripts/**/*.tpl.html']
      },
      livereload: {
        options: {
          livereload: '<%= connect.options.livereload %>'
        },
        files: [
          '<%= yeoman.app %>/{,*/}*.html',
          '.tmp/styles/**/*.css',
          '.tmp/scripts/**/*.js',
          '<%= yeoman.app %>/images/**/*.{png,jpg,jpeg,gif,webp,svg}'
        ]
      }
    },

    // The actual grunt server settings
    connect: {
      options: {
        port: 9000,
        // Change this to '0.0.0.0' to access the server from outside.
        hostname: 'localhost',
        livereload: 35729
      },
      proxies: [
        // proxy login page to dev rails server
        {
          context: '/app/login',
          host: 'localhost',
          port: 5000
        },
        // proxy REST end-points to dev rails server
        {
          context: '/call_center/api',
          host: 'localhost',
          port: 5000
        },
        // rewrite asset requests to use dev path
        {
          context: '/callveyor',
          host: 'localhost',
          port: 9000,
          rewrite: {
            '^/callveyor': '/scripts'
          }
        }
      ],
      livereload: {
        options: {
          open: true,
          middleware: function(connect) {
            return [
              require('grunt-connect-proxy/lib/utils').proxyRequest,
              mountFolder(connect, '.tmp'),
              mountFolder(connect, 'app')
            ]
          }
        }
      },
      test: {
        options: {
          port: 9001,
          base: [
            '.tmp',
            'test',
            '<%= yeoman.app %>'
          ]
        }
      },
      dist: {
        options: {
          base: '<%= yeoman.dist %>'
        }
      }
    },

    // Make sure code styles are up to par and there are no obvious mistakes
    jshint: {
      options: {
        jshintrc: '.jshintrc',
        reporter: require('jshint-stylish')
      },
      all: [
        'Gruntfile.js'
      ]
    },

    // Empties folders to start fresh
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
            '<%= yeoman.dist %>/callveyor/*',
            '!<%= yeoman.dist %>/callveyor/.git*'
          ]
        }]
      },
      server: '.tmp'
    },

    // Add vendor prefixed styles
    autoprefixer: {
      options: {
        browsers: ['last 1 version']
      },
      dist: {
        files: [{
          expand: true,
          cwd: '.tmp/styles/',
          src: '**/**.css',
          dest: '.tmp/styles/'
        }]
      }
    },

    // Automatically inject Bower components into the app
    'bower-install': {
      app: {
        html: '<%= yeoman.app %>/index.html',
        ignorePath: '<%= yeoman.app %>/'
      }
    },


    // Compiles CoffeeScript to JavaScript
    coffee: {
      options: {
        sourceMap: true,
        sourceRoot: ''
      },
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>/scripts',
          src: [
            'app/scripts/*.coffee',
            'app/scripts/dialer/*.coffee',
            '**/*.coffee',
            '!**/*_spec.coffee'
          ],
          dest: '.tmp/scripts',
          ext: '.js'
        }]
      },
      test: {
        files: [{
          expand: true,
          cwd: 'test/spec',
          src: '**/*.coffee',
          dest: '.tmp/spec',
          ext: '.js'
        }]
      }
    },


    // Compiles Sass to CSS and generates necessary files if requested
    compass: {
      options: {
        sassDir: '<%= yeoman.app %>/styles',
        cssDir: '.tmp/styles',
        generatedImagesDir: '.tmp/images/generated',
        imagesDir: '<%= yeoman.app %>/images',
        javascriptsDir: '<%= yeoman.app %>/scripts',
        fontsDir: '<%= yeoman.app %>/fonts',
        importPath: '<%= yeoman.app %>/bower_components',
        httpImagesPath: '/images',
        httpGeneratedImagesPath: '/images/generated',
        httpFontsPath: '/fonts',
        relativeAssets: false,
        assetCacheBuster: false,
        raw: 'Sass::Script::Number.precision = 10\n'
      },
      dist: {
        options: {
          generatedImagesDir: '<%= yeoman.dist %>/callveyor/images/generated'
        }
      },
      server: {
        options: {
          debugInfo: true
        }
      }
    },

    // Renames files for browser caching purposes
    rev: {
      dist: {
        files: {
          src: [
            '<%= yeoman.dist %>/callveyor/scripts/{,*/}*.js',
            '<%= yeoman.dist %>/callveyor/styles/{,*/}*.css',
            '<%= yeoman.dist %>/callveyor/images/{,*/}*.{png,jpg,jpeg,gif,webp,svg}',
            //'<%= yeoman.dist %>/callveyor/fonts/*.{eot,svg,ttf,woff}'
          ]
        }
      }
    },

    // Reads HTML for usemin blocks to enable smart builds that automatically
    // concat, minify and revision files. Creates configurations in memory so
    // additional tasks can operate on them
    useminPrepare: {
      html: '<%= yeoman.app %>/index.html',
      options: {
        // root: 'app/../..',
        dest: '<%= yeoman.dist %>',
        flow: {
          steps: {
            js: ['concat', 'uglifyjs'],
            css: ['concat', 'cssmin']
          },
          post: {
            js: [{
              name: 'uglify',
              createConfig: function(context, block){
                grunt.log.writeln('createConfig should run');
                var generated = context.options.generated;
                generated.options = {
                  preserveComments: false,
                  mangle: false
                };
              }
            }]
          }
        }
      }
    },

    // Performs rewrites based on rev and the useminPrepare configuration
    usemin: {
      html: ['<%= yeoman.dist %>/callveyor/index.html'],
      css: ['<%= yeoman.dist %>/callveyor/styles/{,*/}*.css'],
      options: {
        assetsDirs: ['<%= yeoman.dist %>']
      }
    },

    // The following *-min tasks produce minified files in the dist folder
    imagemin: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>/images',
          src: '{,*/}*.{png,jpg,jpeg,gif}',
          dest: '<%= yeoman.dist %>/callveyor/images'
        }]
      }
    },
    svgmin: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>/images',
          src: '{,*/}*.svg',
          dest: '<%= yeoman.dist %>/callveyor/images'
        }]
      }
    },
    htmlmin: {
      dist: {
        options: {
          collapseWhitespace: true,
          collapseBooleanAttributes: true,
          removeCommentsFromCDATA: true,
          removeOptionalTags: true
        },
        files: [{
          expand: true,
          cwd: '<%= yeoman.dist %>/callveyor',
          src: ['index.html'],
          dest: '<%= yeoman.htmlDist %>',
          rename: function(dest, src) {
            return dest + 'show.html.erb';
          }
        }]
      }
    },

    // Allow the use of non-minsafe AngularJS files. Automatically makes it
    // minsafe compatible so Uglify does not destroy the ng references
    ngmin: {
      dist: {
        files: [{
          expand: true,
          cwd: '.tmp/concat/scripts',
          src: '**/*.js',
          dest: '.tmp/concat/scripts'
        }]
      }
    },

    // Compile angular templates into javascript for faster loading
    // and wrap them an angular module, storing them in $templateCache.
    // Templates are still available via ajax calls.
    ngtemplates: {
      options: {
        prefix: '/callveyor',
        url: function(url) {
          return url.replace('callveyor', 'scripts');
        },
        htmlmin: {
          collapseBooleanAttributes:      true,
          collapseWhitespace:             true
        },
        usemin: '<%= yeoman.dist %>/callveyor/scripts/app.js'
      },
      'callveyor.dialer': {
        module: 'callveyor.dialer',
        standalone: false,
        dest: 'app/scripts/dialer-templates.js',
        cwd: 'app/scripts',
        src: [
          'dialer/*.tpl.html',
          'dialer/{hold,ready,stop,wrap}/*.tpl.html',
          'dialer/active/**/*.tpl.html'
        ],
      },
      'callveyor.contact': {
        module: 'callveyor.contact',
        standalone: false,
        dest: 'app/scripts/contact-templates.js',
        cwd: 'app/scripts',
        src: [
          'dialer/contact/*.tpl.html'
        ]
      },
      'callveyor.household': {
        module: 'callveyor.household',
        standalone: false,
        dest: 'app/scripts/household-templates.js',
        cwd: 'app/scripts',
        src: [
          'dialer/household/*.tpl.html'
        ]
      },
      'idFlash': {
        module: 'idFlash',
        standalone: false,
        dest: 'app/scripts/flash-templates.js',
        cwd: 'app/scripts',
        src: [
          'common/id_flash/*.tpl.html'
        ]
      },
      /*
      TODO:
      put survey-templates.js somewhere useful for tests
      update callveyor section to include scripts/survey
      */
      survey: {
        module: 'survey',
        standalone: false,
        dest: 'app/scripts/survey-templates.js',
        cwd: 'app/scripts',
        src: 'survey/*.tpl.html'
      }
    },

    // Replace Google CDN references
    // cdnify: {
    //   dist: {
    //     html: ['<%= yeoman.dist %>/*.html']
    //   }
    // },

    // Copies remaining files to places other tasks can use
    copy: {
      dist: {
        files: [{
          expand: true,
          dot: true,
          cwd: '<%= yeoman.app %>',
          dest: '<%= yeoman.dist %>/callveyor',
          src: [
            // '*.{ico,png,txt}',
            // '.htaccess',
            'index.html',
            // 'views/{,*/}*.html',
            // 'bower_components/**/*',
            // 'images/{,*/}*.{webp}',
            'fonts/*.{eot,svg,ttf,woff}'
          ]
        }, {
          expand: true,
          cwd: '.tmp/images',
          dest: '<%= yeoman.dist %>/callveyor/images',
          src: ['generated/*']
        }, {
          expand: true,
          cwd: '.tmp/concat/callveyor/scripts',
          dest: '<%= yeoman.dist %>/callveyor/scripts',
          src: ['*.js']
        }]
      },
      styles: {
        expand: true,
        cwd: '<%= yeoman.app %>/styles',
        dest: '.tmp/styles/',
        src: '{,*/}*.css'
      }
    },

    // Run some tasks in parallel to speed up the build process
    concurrent: {
      server: [
        'coffee:dist',
        'compass:server'
      ],
      test: [
        'coffee:dist',
        'compass'
      ],
      dist: [
        'coffee',
        'compass:dist',
        'imagemin',
        'svgmin'
      ]
    },

    // Test settings
    karma: {
      unit: {
        configFile: 'karma.conf.js'
      }
    }
  });


  grunt.registerTask('serve', function (target) {
    if (target === 'dist') {
      return grunt.task.run(['build', 'connect:dist:keepalive']);
    }

    grunt.task.run([
      'clean:server',
      'bower-install',
      'configureProxies',
      'ngconstant:dev',
      'concurrent:server',
      'autoprefixer',
      'connect:livereload',
      'watch'
    ]);
  });

  grunt.registerTask('server', function () {
    grunt.log.warn('The `server` task has been deprecated. Use `grunt serve` to start a server.');
    grunt.task.run(['serve']);
  });

  grunt.registerTask('test', [
    'clean:server',
    'ngconstant:test',
    'concurrent:test',
    'ngtemplates',
    'autoprefixer',
    'connect:test',
    'karma'
  ]);

  grunt.registerTask('build', [
    'clean:dist',
    'bower-install',
    'ngconstant:dist',
    'useminPrepare',
    'concurrent:dist',
    'autoprefixer',
    'ngtemplates',
    'concat',
    'ngmin',
    'copy:dist',
    // 'cdnify',
    'cssmin',
    'uglify',
    'rev',
    'usemin',
    'htmlmin'
  ]);

  grunt.registerTask('default', [
    'newer:jshint',
    'test',
    'build'
  ]);
};
