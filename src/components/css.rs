pub struct CSS {
    pub dark: &'static str,
    pub sepia: &'static str,
    pub light: &'static str,
    pub center: &'static str,
    pub serif: &'static str,
    pub sans: &'static str,
    pub mono: &'static str,
}

impl CSS {
    pub fn new() -> CSS {
        let dark = &"
    html {
      font-size: 1rem;
      width: 100%;
      margin: 0 auto;
    }
    p {
      font-size: 1.1rem;
      line-height: 1.66rem;
      width: 100%;
      color: #C3C3C1;
    }
    h1,
    h2,
    h3,
    h4,
    h5,
    h6 {
      font-style: bold;
      margin-top: 2rem;
      line-height: 2rem;
    }
    h1 {
      font-size: 2rem;
      text-transform: uppercase;
    }
    h2 {
      font-size: 1.5rem;
      text-transform: uppercase;
    }
    h3 {
      font-size: 1.25rem;
    }
    h4 {
      font-size: 1.125rem;
    }
    h5 {
      font-size: 1.1rem;
    }
    h6 {
      font-size: 1rem;
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
      color: #C3C3C3;
      background-color: #111111;
      font-weight: 400;
      line-height: 1.4rem;
      margin-left: 40px;
      margin-right: 40px;
      margin-top: 40px;
      margin-bottom: 40px;
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
      background-color: #2b2b2b;
    }
    table th,
    table td {
      padding: 8px 13px;
      border: 1px solid #2b2b2b;
    }
    table tr {
      border-top: 1px solid #2b2b2b;
    }
    img {
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
    code{
      display: inline-block;
      padding: 0 0.25rem;
      background-color: #23241c;
      border: 1px solid #23241c;
      border-radius: 4px;
      font-family: 'Quilt Mono', monospace;
      font-weight: normal;
    }
    pre code{
      display: block;
      margin: 1rem auto;
      overflow-x: scroll;
      padding: 0.5em;
    }
    blockquote {
      margin: 0;
      border-left: 5px solid #7E8087;
      font-style: italic;
      padding-left: .8rem;
      margin-left: .8rem;
      text-align: left;
    }
    blockquote > p {
      color: inherit;
      margin-top: 20px;
      margin-bottom: 20px;
      padding-top: 20px;
      padding-bottom: 20px;
    }
    ul {
      list-style: disc;
    }
    ul>li {
      font-size: 18px;
    }
    hr {
      overflow: visible;
      padding: 0;
      border: none;
      color: inherit;
      text-align: center;
    }
    hr:after {
      content: \"...\";
      letter-spacing: .6em;
      display: inline-block;
      position: relative;
      top: -0.3rem;
      font-size: 1.65em;
      padding: 0 0.25em;
      background: inherit;
    }
        "[..];

        let sepia = &"
    html {
      font-size: 1rem;
      width: 100%;
      margin: 0 auto;
    }
    p {
      font-size: 1.1rem;
      line-height: 1.66rem;
      width: 100%;
      color: #3b3228;
    }
    h1,
    h2,
    h3,
    h4,
    h5,
    h6 {
      font-style: bold;
      margin-top: 2rem;
      line-height: 2rem;
    }
    h1 {
      font-size: 2rem;
      text-transform: uppercase;
    }
    h2 {
      font-size: 1.5rem;
      text-transform: uppercase;
    }
    h3 {
      font-size: 1.25rem;
    }
    h4 {
      font-size: 1.125rem;
    }
    h5 {
      font-size: 1.1rem;
    }
    h6 {
      font-size: 1rem;
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
      color: #3b3228;
      background-color: #f8f4ef;
      font-weight: 400;
      line-height: 1.4rem;
      margin-left: 40px;
      margin-right: 40px;
      margin-top: 40px;
      margin-bottom: 40px;
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
      background-color: #e0d0b9;
    }
    table th,
    table td {
      padding: 8px 13px;
      border: 1px solid #e0d0b9;
    }
    table tr {
      border-top: 1px solid #e0d0b9;
    }
    img {
      height: auto;
      margin: 0 auto;
    }
    a,
    a:visited,
    a:hover,
    a:focus,
    a:active {
      color: #00897b;
    }
    code{
      display: inline-block;
      padding: 0 0.25rem;
      background-color: #e0d0b9;
      border: 1px solid #e0d0b9;
      border-radius: 4px;
      font-family: 'Quilt Mono', monospace;
      font-weight: normal;
    }
    pre code{
      display: block;
      margin: 1rem auto;
      overflow-x: scroll;
      padding: 0.5em;
    }
    blockquote {
      margin: 0;
      border-left: 5px solid #7e6e62;
      font-style: italic;
      padding-left: .8rem;
      margin-left: .8rem;
      text-align: left;
    }
    blockquote > p {
      color: inherit;
      margin-top: 20px;
      margin-bottom: 20px;
      padding-top: 20px;
      padding-bottom: 20px;
    }
    ul {
      list-style: disc;
    }
    ul>li {
      font-size: 18px;
    }
    hr {
      overflow: visible;
      padding: 0;
      border: none;
      color: inherit;
      text-align: center;
    }
    hr:after {
      content: \"...\";
      letter-spacing: .6em;
      display: inline-block;
      position: relative;
      top: -0.3rem;
      font-size: 1.65em;
      padding: 0 0.25em;
      background: inherit;
    }

        "[..];

        let light = &"
    html {
      font-size: 1rem;
      width: 100%;
      margin: 0 auto;
    }

    p {
      font-size: 1.1rem;
      line-height: 1.66rem;
      width: 100%;
      color: #191919;
    }

    h1,
    h2,
    h3,
    h4,
    h5,
    h6 {
      font-style: bold;
      margin-top: 2rem;
      line-height: 2rem;
    }

    h1 {
      font-size: 2rem;
      text-transform: uppercase;
    }

    h2 {
      font-size: 1.5rem;
      text-transform: uppercase;
    }

    h3 {
      font-size: 1.25rem;
    }

    h4 {
      font-size: 1.125rem;
    }

    h5 {
      font-size: 1.1rem;
    }

    h6 {
      font-size: 1rem;
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
      color: #333;
      background-color: #FFF;
      line-height: 1.4rem;
      margin-left: 40px;
      margin-right: 40px;
      margin-top: 40px;
      margin-bottom: 40px;
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
      background-color: #dddddd;
    }

    table th,
    table td {
      padding: 8px 13px;
      border: 1px solid #F0F0F0;
    }

    table tr {
      border-top: 1px solid #F0F0F0;
    }

    img {
      height: auto;
      margin: 0 auto;
    }

    a,
    a:visited,
    a:hover,
    a:focus,
    a:active {
      color: #0073c5;
    }

    code{
      display: inline-block;
      padding: 0 0.25rem;
      background-color: #F0F0F0;
      border: 1px solid #F0F0F0;
      border-radius: 4px;
      font-family: 'Quilt Mono', monospace;
      font-weight: normal;
    }

    pre code{
      display: block;
      margin: 1rem auto;
      overflow-x: scroll;
      padding: 0.5em;
    }

    blockquote {
      margin: 0;
      border-left: 5px solid #8d8d8d;
      font-style: italic;
      padding-left: .8rem;
      margin-left: .8rem;
      text-align: left;
    }

    blockquote > p {
      color: inherit;
      margin-top: 20px;
      margin-bottom: 20px;
      padding-top: 20px;
      padding-bottom: 20px;
    }

    ul {
      list-style: disc;
    }

    ul>li {
      font-size: 18px;
    }

    hr {
      overflow: visible;
      padding: 0;
      border: none;
      color: inherit;
      text-align: center;
    }
    hr:after {
      content: \"...\";
      letter-spacing: .6em;
      display: inline-block;
      position: relative;
      top: -0.3rem;
      font-size: 1.65em;
      padding: 0 0.25em;
      background: inherit;
    }

        "[..];

        let center = &"
        h1,
        h2,
        h3 {
            text-align: center;
        }
        "[..];

        let serif = &"
        body,
        html {
            font-family: Times New Roman, Times, serif;
        }
        "[..];

        let sans = &"
        body,
        html {
            font-family: Open Sans, Verdana, Geneva, Tahoma, sans-serif;
        }
        "[..];

        let mono = &"
        body,
        html {
            font-family: Quilter Mono, Courier, monospace;
        }
        "[..];


        CSS {
            dark,
            light,
            sepia,
            center,
            serif,
            sans,
            mono,
        }
    }
}
