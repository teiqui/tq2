/* global module, require, __dirname */

const Path                    = require('path')
const MiniCssExtractPlugin    = require('mini-css-extract-plugin')
const TerserPlugin            = require('terser-webpack-plugin')
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin')
const CopyWebpackPlugin       = require('copy-webpack-plugin')

module.exports = (env, options) => {
  const devMode = options.mode !== 'production'

  return {
    cache: devMode ? {type: 'memory'} : false,
    devtool: devMode ? 'eval-cheap-module-source-map' : undefined,
    entry: ['./js/app.js', './css/app.scss'],
    watch: devMode,

    optimization: {
      minimizer: [
        new TerserPlugin({parallel: true}),
        new OptimizeCSSAssetsPlugin({})
      ]
    },

    output: {
      filename: 'js/app.js',
      path: Path.resolve(__dirname, '../priv/static')
    },

    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader'
          }
        },

        {
          test: /\.[s]?css$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',

            {
              loader:  'sass-loader',
              options: {
                sourceMap: devMode,
                sassOptions: {
                  includePaths: [
                    Path.resolve(__dirname, 'node_modules/bootstrap'),
                    Path.resolve(__dirname, 'node_modules/bootswatch')
                  ]
                }
              }
            }
          ]
        },
        {
          test: /\.(woff|woff2|eot|ttf|otf)$/,
          loader: 'file-loader',
          options: {
            outputPath: 'fonts',
            publicPath: '/fonts'
          }
        }
      ]
    },

    plugins: [
      new MiniCssExtractPlugin({filename: 'css/app.css'}),
      new CopyWebpackPlugin({
        patterns: [
          {
            from: 'static/',
            globOptions: {
              dot: true
            }
          }
        ]
      })
    ],

    resolve: {
      alias: {
        phoenix_html: `${__dirname}/../deps/phoenix_html/priv/static/phoenix_html.js`
      }
    }
  }
}
