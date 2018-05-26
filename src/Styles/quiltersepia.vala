/*
The MIT License (MIT)

Copyright (c) 2017 Lains

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

public class Quilter.Styles.quiltersepia {
  public const string css="""
    html {
      font-size: 16px;
    }

    p {
      font-size: 1rem;
      color: #2D1708;
    }

    h1,
    h2,
    h3,
    h4,
    h5,
    h6 {
      font-style: bold;
    }

    h1 {
      margin-top: 0;
      margin-bottom: 1em;
      font-size: 2rem;
    }

    h2 {
      margin-top: 0;
      margin-bottom: 1em;
      font-size: 1.5rem;
    }

    h3 {
      margin-top: 0;
      margin-bottom: 1em;
      font-size: 1.25rem;
    }

    h4 {
      margin-top: 0;
      margin-bottom: 1em;
      font-size: 1rem;
    }

    h5 {
      margin-top: 0;
      margin-bottom: 1em;
      font-size: .875rem;
    }

    h6 {
      margin-top: 0;
      margin-bottom: 1em;
      font-size: .75rem;
    }

    small {
      font-size: .7em;
    }

    img,
    canvas,
    iframe,
    video,
    select,
    textarea {
      display: block;
      max-width: 50%;
    }

    body {
      color: #2D1708;
      background-color: #F0E8DD;
      font-family: 'Open Sans', Helvetica, sans-serif;
      font-weight: 400;
      line-height: 1.4rem;
      margin-left: 80px;
      margin-right: 80px;
      margin-top: 40px;
      max-width: 50rem;
      text-align: left;
    }

    table {
      border-spacing: 0;
      border-collapse: collapse;
      margin-top: 0;
      margin-bottom: 16px;
    }

    table th {
      font-weight: bold;
      background-color: #8C7A6D;
    }

    table th,
    table td {
      padding: 8px 13px;
      border: 1px solid #8C7A6D;
    }

    table tr {
      border-top: 1px solid #8C7A6D;
    }

    img {
      border-radius: .5rem;
      height: auto;
      margin: 0 auto;
    }

    a,
    a:visited,
    a:hover,
    a:focus,
    a:active {
      color: #1d99f3;
    }

    code {
      font-family: 'Quilt Mono', monospace;
      text-align: left;
      padding: 1rem !important;
      border-radius: 5px;
    }

    blockquote {
      margin: 0;
      border-left: 5px solid #8C7A6D;
      font-style: italic;
      padding-left: .8rem;
      text-align: left;
    }
    
    blockquote > p {
      color: #8C7A6D;
      margin-top: 20px;
      margin-bottom: 20px;
      padding-top: 20px;
      padding-bottom: 20px;
    }

    ul {
      list-style: disc;
    }
  
    ul, ol {
      margin-left: -40px;
    }
  """;
}
