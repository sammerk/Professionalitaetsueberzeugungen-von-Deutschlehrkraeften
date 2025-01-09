// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [Was kennzeichnet Professionalität in der Deutsch-Fachdidaktik (Sprache)?],
  subtitle: [Analysen offen und geschlossen erfasster Überzeugungen von Deutschlehrkräften.],
  authors: (
    ( name: [Samuel Merk],
      affiliation: [1],
      email: [] ),
    ( name: [Colin Cramer],
      affiliation: [2],
      email: [] ),
    ),
  date: [2025-01-04],
  lang: "de",
  abstract: ["Professionalität" von Lehrkräften wird einerseits bildungswissenschaftlich theoretisiert und modelliert (z.B. im sog. kompetenzorientierten oder im strukturtheoretischen Ansatz), andererseits haben Lehrkräfte Überzeugungen bzgl. der Frage, was Professionalität in ihrem Beruf ausmacht. Der vorliegende Beitrag untersucht, inwiefern diese Überzeugungen den bildungswissenschaftlichen Ansätzen ähnlich sind und ob sie spezifisch für einen fachdidaktischen Kontext sind. In einem faktorenanalytischen Ansatz zeigten sich Überzeugungen zu Professionalität in der Fachdidaktik Deutsch als metrisch invariant gegenüber allgemeiner Professionalitätsüberzeugungen, wichen jedoch substantiell von der a priori Struktur der bildungswissenschaftlichen Ansätze ab. Word Embeddings von Freitextantworten zeigten jedoch gleichzeitig eine Korrespondenz zu der bildungswissenschaftlich implizierten Gliederung. Inwiefern aus diesen Befunden auf eine kognitive Repräsentation bildungswissenschaftlicher Professionalitätsansätze in den Überzeugungen von Lehrkräften geschlossen werden kann, wird diskutiert.

],
  abstract-title: "Zusammenfassung",
  toc_title: [Inhaltsverzeichnis],
  toc_depth: 3,
  cols: 1,
  doc,
)

== Einleitung (3k)
<einleitung-3k>
Die bildungswissenschaftliche Forschung hat sich intensiv mit der Frage nach der Professionalität von Lehrkräften auseinandergesetzt und dabei diverse, oft komplementäre Theorien und Konzepte generiert @cramer2023. Während z.B. soziologisch inspirierte Arbeiten für die Profession charakteristische Antinomien identifizierten , topologisierten Arbeiten aus der pädagogischen Psychologie Wissensbestände, Überzeugungen und motivationale Variablen die sich in der Literatur als prädiktiv für Outcomes auf Ebene der Schülerinnen und Schüler zeigten @baumert2006@krauss2004@shulman1986. Weitere Forschungsstränge bearbeiteten etwa in der Tradition erziehungswissenschaftlicher Biografieforschung @bauer2000@terhart1992 die besondere Bedeutung von berufsbiografischen Übergängen und fassten Professionalität unter anderem als Sensibilität für die Bedeutung der eigenen Biografie und das kontinuierliche Bewältigen aktueller berufsbiografischer Herausforderungen auf. Die Frage nach Professionalität im Lehrerinnen- und Lehrerberuf hat auch Eingang in die Bildungsstandards der Ständigen Konferenz der Kultusminister der Länder in der Bundesrepublik Deutschland gefunden. Dementsprechend werden an Universitäten und pädagogischen Hochschulen die zuvor genannten bildungswissenschaftlichen Professionalitätsansätze gelehrt @hohenstein2014. Es kann jedoch begründet angenommen werden, dass Lehrkräfte in diesen Lernsituationen umfangreiche, bereits bestehende implizite wie explizite Überzeugungen @fives2012@merk2020 bzgl. der Frage der Professionalität einbringen. Dies hätte Konsequenzen für die Professionalisierungspraxis @cramer2023, da diese Überzeugungen etwa über die ihnen zugeschriebene Filter-, Rahmungs- und Handlungsleitungsfunktion @fives2012 dazu führen können, dass (angehende) Lehrkräfte bestimmte Lerngelegenheiten unterschiedlich wählen und nutzen. Dementsprechend liegt erste Forschung vor, die untersucht, inwiefern Überzeugungen zur Professionalität von Lehrkräften in ihrer Struktur den bildungswissenschaftlichen Theorien entspricht, wobei die Ergebnisse sowohl auf Ähnlichkeiten und Abweichungen zwischen Überzeugungsstruktur und Theorien hinweisen @cramer2023. Die Ambiguität dieser Ergebnisse, deren unklare Generalisierbarkeit sowie die grundsätzliche Diskussion um die Erfassbarkeit von Überzeugungen zu Professionalität mit geschlossenen Fragebogenitems @merk2023 nimmt die vorliegende Studie zum Anlass um a) zu versuchen, die von Cramer et al. #cite(<cramer2023>, form: "year") gefundene Faktorenstruktur der Professionalitätsüberzeugungen domänenspezifisch zu replizieren b) die Faktorenstruktur von allgemeinen Professionalitätsüberzeugungen und Professioalitätsüberzeugungen in der Fachdidaktik zu vergleichen und b) die Ähnlichkeit des Inhalts von offen erfassten Überzeugungen und bildungswissenschaftlichen Theorien zur Professionalität von Lehrerinnen und Lehrern mit Natural Language Processing Methoden @bittermann2024 zu untersuchen.

== Theoretischer Hintergrund (8K)
<theoretischer-hintergrund-8k>
=== Professionalität von Lehrkräften
<sec-professionalitat-von-lehrkraften>
In den Bildungswissenschaften ist in den letzten zwei Dekaden eine lebendige, teils auch kontroverse Diskussion um die Charakteristika professionellen Handelns im Lehrerberuf zu verzeichnen, die verschiedene Ansätze zur Beschreibung von Professionalität hervorgebracht hat, welche im Folgenden beschrieben werden sollen.

==== Strukturtheoretischer Ansatz
<strukturtheoretischer-ansatz>
Ausgehend von soziologisch geprägten Arbeiten Oevermanns #cite(<oevermann1996>, form: "year") wirft der strukturtheoretische Ansatz der Professionalität von Lehrkräften ein besonderes Augenmerk auf die beruflichen Rahmenbedingungen von Lehrerinnen und Lehrern wie etwa Rollenerwartungen oder soziale Gefüge @helsper2014. In der Rezeption dieses Ansatzes haben sogenannte "Antinomien" oder "professionelle Paradoxien" des Lehrerinnen- und Lehrerberufes besondere Aufmerksamkeit erfahren @baumert2006. Sie beschreiben nicht auflösbare, aber charakteristische Widersprüche in den professionellen Anforderungen wie etwa die simultane Erfordernis von Nähe und Distanz zwischen Lehrkräften und Schülerinnen und Schülern.

==== Kompetenzorientierter Ansatz
<kompetenzorientierter-ansatz>
Der kompetenzorientierte Ansatz hingegen versucht, Wissensbestände, Überzeugungen, motivationale Orientierungen und selbstregulative Fähigkeiten von Lehrkräften zu systematisieren, die ein erfolgreicheres Handeln wahrscheinlicher machen. Dabei wird Erfolg meist als gesteigerte (operationaliserbare) Outcomes auf Ebene der Schülerinnen und Schüler definiert, wie z.B. deren akademische Leistung oder Motivation. Diese Systematisierung steht in der Tradition der Wissenstopologie Shulmans #cite(<shulman1986>, form: "year") und des Expertiseansatzes der Lehrerprofessionalität @bromme1992. Häufig zitiert werden Topologien, welche die für professionelle Kompetenz konstitutiven Wissensdomänen Fachwissen, Fachdidaktisches Wissen, Pädagogisches Wissen, Organisationales Wissen und Beratungswissen jeweils in disjunkte Subdomänen unterteilen @baumert2006@konig2020@krauss2004

==== Berufsbiografischer Ansatz
<berufsbiografischer-ansatz>
In der Tradition erziehungswissenschaftlicher Biografieforschung fokussieren Arbeiten die dem berufsbiografischen Ansatz zugeordnet werden (z.B. Bauer, 2000a; Terhart, 2001) @bauer2000@terhart2001 eine stark intraindividuelle Perspektive: Sie betonen, dass Professionalität von Lehrerinnen und Lehrern als "berufsbiographisches Entwicklungsproblem" zu sehen sei @terhart1995c[pp.~238] und leiten daraus die Notwendigkeit einer Sensibilität für die eigene Berufsbiografie, einer besonderen Berücksichtigung beruflicher Übergänge (etwa zu Beginn des Referendariats) oder des Aufbaus eines beruflichen Selbsts ab.

==== Metareflexiver Ansatz
<metareflexiver-ansatz>
Die bisher genannten Ansätze haben (neben weiteren) längst Eingang in die institutionalisierte Lehrkräftebildung gefunden. Dies nahmen Cramer et al. #cite(<cramer2019>, form: "year") zum Anlass, Professionalität als mehrperspektivische Betrachtung des eigenen Handelns unter Berücksichtigung aller drei bisher genannter Ansätze sowie deren Unterschiede und Gemeinsamkeiten zu definieren. Danach rekurrieren professionelle Lehrkräfte beim Treffen von Entscheidungen auf Handlungsoptionen, die im Lichte …. adäquat erscheinen. Dabei reflektieren sie verschiedene Handlungsoptionen nicht nur mehrperspektivisch entlang verschiedener situationsadäquater Theorien und Konzepte, sondern auch deren terminologische Differenzen und differentielle Axiomatiken @cramer2023a.

== Überzeugungen von Lehrkräften
<überzeugungen-von-lehrkräften>
Überzeugungen von Lehrkräften sind ein beliebter Forschungsgegenstand @fives2019@pajares1992@skott2015 in der Lehrerinnen- und Lehrerbildungsforschung. Überzeugungen werden zum einen als sehr wirkmächtig konzeptualisert - ihnen wird etwa eine Filter- Rahmungs- und Handlungsleitungsfunktion zugeschrieben @fives2019. Andererseits gelten sie als vergleichsweise ökonomisch via Fragebogen erfassbar @merk2020. Da Überzeugungen meist als subjektive Wahrheitspropositionen definiert werden @skott2015, liegt es nahe, die Forschung zu Überzeugungen von Lehrerinnen und Lehrern nach dem Gegenstandsbereich der Wahrheitspropositionen zu gliedern: Also etwa lehr- lerntheoretische Überzeugungen @dubberke2008@turner2009@reusser2014, epistemische Überzeugungen @blömeke2008@fives2008@hofer2012, Überzeugungen zu heterogenen Lerngruppen @gebauer2013 oder eben Überzeugungen zur Professionalität von Lehrkräften @cramer2023. Überzeugungen zu verschiedenen Gegenstandsbereichen gelten jedoch als teilweise abhängig voneinander, wenngleich nicht notwendigerweise konsistent: So weisen Lehrkräfte die hochgradig transmissive Lerntheoretische Überzeugungen für das Fach Mathematik aufweisen auch eher transmissive Lerntheoretische Überzeugungen für das Fach Physik auf (Abhängigkeit), gleichzeitig gibt es Evidenz dafür, dass Lehrkräfte davon überzeugt sind, dass es wichtig ist ihre Praxis durch bildungswissenschaftliche Forschungsergebnisse zu informieren, ohne dies jedoch auch umzusetzen @gold2024@walker2019. Für diese Domänenspezifität und Kontextabhängigkeit von Überzeugungen liegen (insbesondere für epistemische Überzeugungen) umfassende Rahmenmodelle vor @merk2017@muis2006.

=== Professionalitätsüberzeugungen von Lehrkräften
<professionalitätsüberzeugungen-von-lehrkräften>
Empirische Forschung zu Überzeugungen von Lehrkräften zu Professionalität in ihrem Beruf ist im Vergleich zu Forschung zu Überzeugungen zu den anderen zuvor genannten Gegenstandsbereichen eher selten. Es existiert zwar internationale Forschung zu Überzeugungen bzgl. "teachers’ knowledge and ability" @fives2008, "teacher identity" @zembylas2015, "collective beliefs" @tschannen-moran2015 und mit Bezug auf aktuelle bildungspolitische Entwicklungen @Bell2011. Jedoch sind die im vorherigen Abschnitt vorgestellten Theorien der Lehrerinnen- und Lehrerprofessionalität hauptsächlich im deutschsprachigen Kontext prominent, so dass die Seltenheit empirischer Forschung bzgl. Überzeugungen hierzu nicht überrascht. Eine Ausnahme davon stellt die Arbeit von Cramer et al. #cite(<cramer2023>, form: "year") dar. Dort wurde einer vergleichsweise repräsentativen Stichprobe von Lehrkräften eine Batterie von 16 Likertitems vorgelegt, die die Zustimmung zu jeweils einem zentralen Aspekt eines der vier zuvor vorgestellten Ansätze erfasst (z.B. Eine professionelle Lehrperson identifiziert über das gesamte Berufsleben hinweg individuelle Entwicklungsbedarfe/Eine professionelle Lehrperson ist sensibel für die Notwendigkeit, im Beruf fortwährend selbst hinzuzulernen \[berufsbiografischer Ansatz\]; Eine professionelle Lehrperson verfügt über fachliches Wissen als Voraussetzung für den Wissenserwerb ihrer Schülerinnen und Schüler/Eine professionelle Lehrperson ist von lernförderlichen Konzepten des Lehrens und Lernens überzeugt, die wissenschaftlich belegt sind \[kompetenzorientierter Ansatz\]). Diese Items wurden im Zuge der Skalenentwicklung inhaltlich mit Expertinnen und Experten validiert und kognitiven Prätests unterzogen. Konfirmatorische Faktorenanalysen zeigten eine Überlegenheit einer vierdimensionalen Einfachstruktur, bei der jedes Item auf dem ihm a priori zugewiesenen Faktor (Professionalitätsansatz) lud, gegenüber einer einfaktoriellen Lösung. Jedoch lagen inkrementelle wie absolute (globale) Fitmaße unter einschlägigen Benchmarks. Daher führten Cramer et al. #cite(<cramer2023>, form: "year") im Anschluss eine explorative Faktorenanalyse durch, die drei Faktoren ergab. Diese wurden Professionalität als schulisches Handeln, Professionalität als Anwendbarkeit von Wissen und Können und Professionalität als reflexive Haltung genannt. Diese dreidimensionale a posteriori beschriebene Struktur, ist der a priori postulierten Struktur noch ähnlich, da sie nur durch Vertauschung von 6 (inhaltlich sehr plausiblen) Items aus der a priori angenommenen Struktur entsteht (Adjusted Rand Index .29). Unabhängig davon bleibt jedoch unklar, inwiefern das Instrument von Cramer et al. #cite(<cramer2023>, form: "year") Professionalitätsüberzeugungen exhaustiv erfasst, wie domänenspezifisch diese sind und ob sie tatsächlich explizit bei den Befragten kognitiv repräsentiert sind @merk2023: So sind die Ergebnisse auch mit der Annahme vereinbar, dass Lehrkräfte intuitiv Professionalität völlig unähnlich zu den Bildungswissenschaften fassen, den bildungswissenschaftlichen Überlegungen das erste Mal beim Beantworten des Fragebogen begegnen und daher das Instrument von Cramer et al #cite(<cramer2023>, form: "year") eher spontane Urteilsbildungen erfasst als bestehende Überzeugen. Die vorliegende Studie möchte zur Aufklärung dieser Unklarheiten beitragen, indem sie Professionalitätsüberzeugungen von Lehrkräften zunächst mit einem offenen Item und anschließend mit dem Instrument von Cramer et al #cite(<cramer2023>, form: "year") erfasst.

== Forschungsfragen und Hypothesen
<forschungsfragen-und-hypothesen>
=== Forschungsfrage 1 (explorativ, präregistriert)
<forschungsfrage-1-explorativ-präregistriert>
Spiegeln sich die bildungswissenschaftlichen Professionalitätsansätze in den frei formulierten domänenspezifischen Professionalitätsüberzeugungen? Wir haben diesbezüglich keine a priori Hypothesen (explorative Forschungsfrage) und haben daher keine Hypothesen präregistriert.

=== Forschungsfrage 2 (konfirmatorisch, präregistriert)
<forschungsfrage-2-konfirmatorisch-präregistriert>
Lässt sich die von Cramer et al #cite(<cramer2023>, form: "year") gefundene Faktorenstruktur domänenspezifisch für die Fachdidaktik Deutsch (Sprache) replizieren? Wir erwarten, dass die von Cramer et al #cite(<cramer2023>, form: "year") gefundene Faktorenstruktur einer eindimensionalen Faktorenlösung und einer vierdimensionalen Faktorenlösung, die die a priori Strukturierung der Items entlang der vier prominenten Professionalisierungsansätze widerspiegelt, überlegen ist.

=== Forschungsfrage 3 (konfirmatorisch, nicht präregistriert)
<forschungsfrage-3-konfirmatorisch-nicht-präregistriert>
Unterscheiden sich offen und geschlossen erfasste Überzeugungen zur Professionalität in der Deutschdidaktik (Sprache) von Überzeugungen zur Professionalität im Lehrerinnen- und Lehrerberuf im allgemeinen (Domänenspezifität)? Basierend auf einschlägigen Rahmenmodellen und empirischen Befunden gehen wir von kleinen Unterschieden in Struktur- und Ausprägung der Überzeugungen aus.

== Methode (4K)
<methode-4k>
=== Stichprobe
<stichprobe>
Forschungsfragen 1 und 2 wurden mit Daten von $N_1 =$ 206 Deutschlehrkräften (Stichprobe 1: 73.3% weiblich, 17.5% weniger als 11 Dienstjahre, 44.7% mehr als 20 Dienstjahre, 38.8% mindestens ein MINT-Fach) aus Deutschland beantwortet. Diese wurden aus dem Panel eines Felddienstleisters rekrutiert und erhielten als Aufwandentschädigung einen Gutschein im Wert von X. Für die Bearbeitung von Forschungsfrage 3 weitere $N_2 =$ 105 Deutschlehrkräfte (Stichprobe 2: 74.3% weiblich, 13.3% weniger als 11 Dienstjahre, 52.4% mehr als 20 Dienstjahre, 44.8% mindestens ein MINT-Fach) aus demselben Panel rekrutiert. Die Größe von Stichprobe 1 wurde a priori anhand einer Simulationsstudie (#link("Externer%20LINK")[siehe reproduierbarer Code];) determiniert. Die Größe von Stichprobe 2 war nicht a priori geplant und durch Projektressourcen pragmatisch limitiert @lakens2022.

=== Instrument
<instrument>
In beiden Stichproben wurden zunächst die Professionalitätsüberzeugungen der befragten Deutschlehrkräfte mit einem offenen Item erfasst (Wortlaut Stichprobe 1: "#emph[Wir interessieren uns nun dafür, was Ihrer Ansicht nach »Professionalität« in der Deutsch-Fachdidaktik (Sprache) ausmacht. Bitte antworten Sie in ganzen Sätzen um Missverständnisse zu vermeiden und formulieren Sie möglichst drei Aspekte. Eine »professionelle« Lehrperson in der Deutsch-Fachdidaktik (Sprache) …];, Wortlaut Stichprobe 2:"#emph[Wir interessieren uns nun dafür, was Ihrer Ansicht nach »Professionalität« einer Lehrperson ausmacht. Bitte antworten Sie in ganzen Sätzen um Missverständnisse zu vermeiden und formulieren Sie möglichst drei Aspekte. Eine »professionelle« Lehrperson …];”). Danach wurde den Lehrkräften das Instrument von Cramer et al #cite(<cramer2023>, form: "year");vorgelegt. In Stichprobe 1 (domänenspezifische Überzeugungen) lautete der Itemstamm "#emph[Eine professionelle Lehrperson in der Deutsch-Fachdidaktik (Sprache) …];", während in Stichprobe zwei der originale Itemstamm ("#emph[Eine professionelle Lehrperson …];") zur Erfassung globaler Professionalitätsüberzeugungen beibehalten wurde. In beiden Stichproben wurden die 16 Originalitems verwendet. Davon zielen jeweils vier auf die Erfassung der Überzeugungen eines der zuvor geschilderten bildungswissenschaftlichen Ansätze der Professionalität von Lehrkräften (siehe @sec-wortlaut-der-items).

== Statistische Modellierung
<statistische-modellierung>
=== Word Embeddings und Ähnlichkeitsanalyse
<sec-word-embeddings>
Da Forschungsfrage 1 sich für das Vorkommen der Ideen bildungswissenschaftlicher Professionalitätsansätze in den spontan geäußerten Professionalitätsüberzeugungen in Freitextantworten interessiert, wurden zunächst Sentence Embeddings @reimers2019 sowohl aller drei Antworten der Befragten, als auch aller geschlossener 16 Likertitems in zwei große prätrainierte Transformermodelle @reimers2019@greene2024 vorgenommen. Unabhängig von der spezifischen Architektur der jeweiligen Modelle ist deren zentrales Konzept, die semantische Kernaussage eines Satzes als Vektor in einem hochdimensionalen Raum zu repräsentieren @reimers2019. Die semantische Ähnlichkeit zweier Sätze - also zum Beispiel der Freitextantwort "Eine Lehrkraft ist in der Fachdidaktik Deutsch dann professionell, wenn sie fundierte, sicher anwendungsbereite Kenntnisse in Grammatik, Rechtschreibung, Ausdruck, Textsorten, Epochen und Werkkenntnissen hat" und des Items "Eine professionelle Lehrperson verfügt über fachliches Wissen als Voraussetzung für den Wissenserwerb ihrer Schülerinnen und Schüler" kann dann als Winkel zwischen diesen beiden Vektoren quantifiziert werden @kjell2023. Dementsprechend wurden vorliegend alle Ähnlichkeiten von allen offenen Antworten zu allen Items berechnet. Diese Ähnlichkeiten stellten dann die abhängige Variable in einer bayesianischen Mehrebenenregression für beta-verteilte Variablen dar, welche dann mit Dummyvariablen der entsprechenden bildungswissenschaftlichen Ansätze (des betreffenden Items) prädiziert wurden. Nimmt man an, dass die geschlossenen Items jeweils den entsprechenden bildungswissenschaftlichen Ansätz repräsentieren, müsste das Embedding einer Freitextantwort, die z.B. einer kompetenzorientierten Professionalitätsüberzeugung entspricht, ähnlicher zu allen vier kompetenzorientierten Items sein, als zu den Embeddings der restlichen Items.

=== Faktorenanalysen
<sec-faktorenanalysen>
Um die Faktorenstruktur der 16 geschlossenen Items zu evaluieren, wurde wie präregistriert vorgegangen: Es wurde ein eindimensionales Modell, ein vierdimensionales Modell das die a priori Struktur (strukturtheoretischer, kompetenzorientierter, berufsbiografischer und metareflektiver Ansatz)-beinhaltet und ein vierdimensionales Modell das die empirisch von Cramer et al. #cite(<cramer2023>, form: "year") gefundene Struktur a posteriori Struktur abbildet spezifiziert (jeweils mit -kongenerischen Messmodellen). Die Modellanpassungsgüte wurde dann wie präregistriert anhand des $chi^2$-Wertes, des Confirmatory Fit Indexes (CFI), des Root Mean Square Error of Approximation (RMSEA), den Standardized Root Mean Square Residuals (SRMR), dem Bayesian Information Criterion (BIC) und dem Akaike Information Criterion (AIC) verglichen (siehe Präregistrierung). Um die nicht präregistrierte Forschungsfrage 3 zu beantworten, wurden die Autoren der Originalstudie für die Möglichkeit einer Sekundäranalyse angefragt. Nach Erhalt der Daten wurden diese mit der vorliegenden Stichprobe zusammengelegt und anschließend Messinvarianzanalysen @luong2021@robitzsch2022 des in beiden Stichproben überlegenen a posteriori Modells mittels konfirmatorischer Mehrgruppen-Faktorenmodelle durchgeführt.

== Ergebnisse (6K)
<ergebnisse-6k>
=== Forschungsfrage 1
<forschungsfrage-1>
Die $N_1 =$ 206 Deutschlehrkräfte aus Stichprobe 1 gaben im Durschnitt 2.97 frei formulierte Antworten auf die Frage was ihrer Meinung nach Professionalität in der Deutsch-Fachdidaktik (Sprache) ausmacht. Alle Anworten sind im Online-Supplement vollständig abgebildet.

#figure([
#box(image("index_files/figure-typst/fig-embeddings-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Ähnlichkeiten der offenen Antworten zu allen Items, gegliedert nach deren a priori Dimensionen (ST = strukturtheoretischer Ansatz, MR = Metareflektiver Ansatz, KO = kompetenzorientierter Ansatz, BB = berufsbiographischer Ansatz).
]), 
kind: "quarto-float-fig", 
supplement: "Abbildung", 
)
<fig-embeddings>


Um zu eruieren inwiefern diese offenen Antworten Ideen der vier unter @sec-professionalitat-von-lehrkraften beschriebenen bildungswissenschaftlichen Ansätze enthalten, wurde die Ähnlichkeit aller Antworten zu allen Items des Instrumentes von Cramer et al #cite(<cramer2023>, form: "year") in zwei Transformermodellen bestimmt. Diese Ähnlichkeiten zeigten sich als unimodal und sehr ähnlich in ihren Verteiungsformen über die beiden gewählten Transformermodelle hinweg (siehe @fig-embeddings).

#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 8;
#let ncol = 9;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (6, 7), (6, 8), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7), (7, 8), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 8),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
 table.hline(y: 9, start: 0, end: 9, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Embedding], [apriori_faktor], [Min], [Max], [Med], [MW], [SD], [Schiefe], [Kurtosis],
    ),

    // tinytable cell content after
[Ger-RoSBERTa], [BB], [0.107], [0.76], [0.5 ], [0.49], [0.1  ], [-0.565], [3.4],
[Ger-RoSBERTa], [KO], [0.077], [0.79], [0.52], [0.51], [0.105], [-0.506], [3.6],
[Ger-RoSBERTa], [MR], [0.074], [0.72], [0.46], [0.46], [0.09 ], [-0.61 ], [4.2],
[Ger-RoSBERTa], [ST], [0.039], [0.77], [0.43], [0.43], [0.105], [-0.05 ], [3.3],
[OpenAI      ], [BB], [0.708], [0.88], [0.81], [0.81], [0.023], [-0.405], [3.6],
[OpenAI      ], [KO], [0.709], [0.93], [0.84], [0.83], [0.032], [-0.272], [3.3],
[OpenAI      ], [MR], [0.717], [0.89], [0.81], [0.81], [0.024], [0.014 ], [3.6],
[OpenAI      ], [ST], [0.714], [0.9 ], [0.81], [0.81], [0.025], [0.267 ], [3.3],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Deskriptive Verteilungsbeschreibung der Ähnlichkeiten der offenen Antworten zu allen Items (ST = strukturtheoretischer Ansatz, MR = Metareflektiver Ansatz, KO = kompetenzorientierter Ansatz, BB = berufsbiographischer Ansatz).
]), 
kind: "quarto-float-tbl", 
supplement: "Tabelle", 
)
<tbl-embeddings>


Die unterschiedlichen Mittelwerte in @fig-embeddings deuten auf eine Repräsentation der in den bildungswissenschaftlichen Professionalitätsansätzen enthaltenen Ideen in den offenen Antworten hin. Um diese auch inferenzstatistisch zu modellieren wurden bayesianische Mehrebenen-Beta-Regressionsmodelle spezifiziert, in denen die Ähnlichkeiten zwischen Itemwortlaut und Wortlaut der offenen Antwort die abhängige Variable darstellten und dummykodierte Indikatorvariablen der a priori Zuordnung der Variablen die unabhängige Variable. Um der genesteten Struktur der Daten (mehrere Antworten pro Lehrkraft) Rechnung zu tragen, wurden Random Intercepts im R-Paket brms @bürkner2017 spezifiziert (siehe @lst-reg01), welches wiederum die probabilistische Sprach Stan @standevelopmentteam2024 nutzt. Für alle zu schätzenden Parameter wurden nicht-informative Priorverteiltungen spezifiziert, wodurch die Punktschätzung vollständig durch die Likelihood der Daten getrieben ist @winter2021 @lemoine2019@winter2021. Die numerische Qualität der vier unabhängigen Marcov-Chain-Monte-Carlo-Samplings wurde mithilfe von Trace-Plots, $hat(R)$-Werten sowie Bulk- und Tail-Effective-Sample-Sizes bewertet.

#figure([
#set align(left)
#block[
```r
reg_grosberta01 <- 
  brm(bf(similarity ~ apriori_faktor + (1|PID),
         phi ~ apriori_faktor + (1|PID)),
      data = 
        data_grosberta %>% 
        filter(spezifität == "Fachdidaktik"),
      cores = 4,
      iter = 6000,
      family = Beta(),
      seed = 1893)
plot(reg_grosberta01)
pp_check(reg_grosberta01)
summary(reg_grosberta01)

reg_openai01 <- 
  brm(bf(similarity ~ apriori_faktor + (1|PID),
         phi ~ apriori_faktor + (1|PID)),
      data = 
        data_openai %>% 
        filter(spezifität == "Fachdidaktik"),
      cores = 4,
      iter = 6000,
      family = Beta(),
      seed = 1893)
plot(reg_openai01)
pp_check(reg_openai01)
summary(reg_openai01)

# Da das MCMC Sampling zeitintensiv ist, werden die Objekte gespeichert
save(reg_grosberta01, reg_openai01, 
     file = "_data/regs01.RData")
```

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-lst", 
supplement: "Listing", 
)
<lst-reg01>


Betrachtet man die bedingten Effekte dieser Modelle (siehe @tbl-conditional-effects-embeddings), fällt auf, dass deren Punktschätzung sehr gut mit den deskriptiven Ergebnissen korrespondiert und die 95%-Kredibilitätsintervalle sehr eng sind.

#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 10;
#let ncol = 3;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 2), (0, 3), (0, 4), (0, 5), (0, 7), (0, 8), (0, 9), (0, 10),), indent: 1em,),
(pairs: ((0, 1), (0, 6), (1, 1), (1, 6), (2, 1), (2, 6),), align: center,),
(pairs: ((0, 0), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 7), (1, 8), (1, 9), (1, 10), (2, 0), (2, 2), (2, 3), (2, 4), (2, 5), (2, 7), (2, 8), (2, 9), (2, 10),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 3, stroke: 0.05em + black),
 table.hline(y: 11, start: 0, end: 3, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 3, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[A priori Faktor], [Ähnlichkeit], [95%-CI],
    ),

    // tinytable cell content after
table.cell(colspan: 3)[Ger-RoSBERTa Embeddings],
[BB], [0.490], [[0.481; 0.499]],
[KO], [0.512], [[0.502; 0.521]],
[MR], [0.453], [[0.444; 0.462]],
[ST], [0.432], [[0.423; 0.441]],
table.cell(colspan: 3)[OpenAI Embeddings],
[BB], [0.812], [[0.810; 0.814]],
[KO], [0.833], [[0.831; 0.835]],
[MR], [0.808], [[0.806; 0.810]],
[ST], [0.809], [[0.806; 0.811]],
    // tinytable footer after
  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Bedingte Effekte der Mehrebenen-Beta-Regressionsmodelle (ST = strukturtheoretischer Ansatz, MR = Metareflektiver Ansatz, KO = kompetenzorientierter Ansatz, BB = berufsbiographischer Ansatz).
]), 
kind: "quarto-float-tbl", 
supplement: "Tabelle", 
)
<tbl-conditional-effects-embeddings>


=== Forschungsfrage 2
<forschungsfrage-2>
Da Forschungsfrage 2 sich für die Replikation der Ergebnisse von Cramer et al. #cite(<cramer2023>, form: "year") interessiert, wurde wie präregistriert die Passung dreier konfirmatorischer Faktorenanalysen verglichen (siehe @sec-faktorenanalysen).

Dabei zeigte sich auf den vorliegenden Daten (Stichprobe 1) passend zur präregistrierten Hypothese der beste Fit für das a-Posteriori-Modell (χ² = 120.300, #emph[df] = 62, RMSEA = 0.072, SRMR = 0.062, BIC = 6268.2, AIC = 6175.5) im Vergleich zur eindimensionales Lösung (χ² = 222.900, #emph[df] = 104, RMSEA = 0.080, SRMR = 0.073, BIC = 7478.0, AIC = 7376.2), welche wiederum dem a-priori-Modell (χ² = 185.400, #emph[df] = 98, RMSEA = 0.071, SRMR = 0.070, BIC = 7471.6, AIC = 7350.7) signifikant unterlegen war (Δχ² = 37.503, Δ#emph[df] = 6.000, #emph[p] \< .001). Obwohl diese Ergebnisse der präregistrierten Hypothese entsprechen, muss jedoch angemerkt werden, dass auch das empirisch favorisierte Modell in einigen nicht-präregistrierten Fit-Indices (z.B. Tucker Lewis Index \[TLI\], Confirmatory Fit Index \[CFI\]) Werte aufzeigen, die auf eine mangelnde Passung hinweisen (TLI = 0.850, CFI = 0.880) und zudem die Varianz-Kovarianz-Matrix der latenten Variablen des a-priori-Modells nicht positiv definit war.

=== Forschungsfrage 3
<forschungsfrage-3>
Zur Bearbeitung der Forschungsfrage 3 wurden zwei weitere Datensätze hinzugezogen: Zum Vergleich der offen erfassten globalen und fachdidaktik-spezifischen Professionalitätsüberzeugungen wurden dieselben Regressionsmodelle wie in @sec-word-embeddings spezifiziert, jedoch die Daten von Stichprobe 1 und 2 verwendent und um Interaktionseffekte für die Domänenspezifität ergänzt (siehe @lst-reg02).

#figure([
#set align(left)
#block[
```r
reg_grosberta02 <- 
  brm(bf(similarity ~ apriori_faktor*spezifität + (1|PID),
         phi ~ apriori_faktor*spezifität + (1|PID)),
      data = 
        data_grosberta,
      cores = 4,
      iter = 6000,
      family = Beta(),
      seed = 1893)
plot(reg_grosberta02)
pp_check(reg_grosberta02)
summary(reg_grosberta02)

reg_openai02 <- 
  brm(bf(similarity ~ apriori_faktor*spezifität + (1|PID),
         phi ~ apriori_faktor*spezifität + (1|PID)),
      data = 
        data_openai,
      cores = 4,
      family = Beta(),
      seed = 1893)
plot(reg_openai02)
pp_check(reg_openai02)
summary(reg_openai02)

# Da das MCMC Sampling zeitintensiv ist, werden die Objekte gespeichert
save(reg_grosberta02, reg_openai02, 
     file = "_data/regs02.RData")
```

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-lst", 
supplement: "Listing", 
)
<lst-reg02>


Die Interaktionseffekte sind in @fig-cond-eff-reg-ff3 dargestellt und zeigen im Wesentlichen eine sehr starke Überlappung der Ähnlichkeiten der offenen Antworten zu den Items der bildungswissenschaftlichen Professionalitätsansätze. Die Ähnlichkeiten scheinen also relativ unabhängig davon zu sein, ob die Lehrkräfte dazu aufgefordert wurden zu beschreiben was Professionalität im Lehrerinnen- und Lehrerberuf ausmacht (globale Professionalitätsüberzeugung) oder was Professionalität in der Fachdidaktik Deutsch (Sprache) ausmacht. Gleichzeitig fällt auf, dass die Ähnlichkeiten (mit einer Ausnahme #emph[d] = -0.07) der Antworten auf die Frage nach den globalen Professionalitätsüberzeugungen etwas größer ausfallen (0.05 ≤ #emph[d] ≤ 0.30). Dies ist plausibel, da die Items von Cramer et al. #cite(<cramer2023>, form: "year");, zu denen die Ähnlichkeit der offenen Antworten bestimmt wurde, ebenfalls globale Professionalitätsüberzeugungen erfassen.

#figure([
#box(image("index_files/figure-typst/fig-cond-eff-reg-ff3-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Bedingte Effekte der Mehrebenen-Beta-Regressionsmodelle mit Interaktionseffekten für die Domänenspezifität (Breites Intervall = 95% Kredibilitätintervall, schmales Intervall = MW ± 1SD, ST = strukturtheoretischer Ansatz, MR = Metareflektiver Ansatz, KO = kompetenzorientierter Ansatz, BB = berufsbiographischer Ansatz).
]), 
kind: "quarto-float-fig", 
supplement: "Abbildung", 
)
<fig-cond-eff-reg-ff3>


Abschließend wurden konfirmatorische Zweigruppen-Faktorenanalysen durchgeführt, um die Domänenspezifität auch auf Itemebene zu untersuchen. Dabei wurde sowohl für die a priori als auch die a posteriori Faktorenstruktur in einer Serie von Modellen sukzessive Faktorenstruktur, Ladungen, Intercepts und Residualvarianzen der Items als zwischen den Gruppen gleich restringiert (siehe @sec-faktorenanalysen).

#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 8;
#let ncol = 8;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (6, 7), (6, 8), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7), (7, 8),), fontsize: 0.8em,),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (18.18%, 18.18%, 10.61%, 10.61%, 10.61%, 10.61%, 10.61%, 10.61%),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 8, stroke: 0.05em + black),
 table.hline(y: 9, start: 0, end: 8, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Struktur], [Modell], [χ²], [df], [CFI], [SRMR], [BIC], [P(Δχ²)],
    ),

    // tinytable cell content after
[A priori    ], [Konfigural], [444.936], [196], [0.920], [0.051], [25981.70], [-    ],
[A priori    ], [Metrisch  ], [454.901], [208], [0.921], [0.054], [25915.21], [0.619],
[A priori    ], [Skalar    ], [504.927], [220], [0.908], [0.057], [25888.77], [0.000],
[A priori    ], [Strikt    ], [579.865], [236], [0.890], [0.065], [25861.76], [0.000],
[A posteriori], [Konfigural], [251.698], [124], [0.944], [0.043], [21687.48], [-    ],
[A posteriori], [Metrisch  ], [261.503], [134], [0.944], [0.047], [21633.51], [0.458],
[A posteriori], [Skalar    ], [299.290], [144], [0.932], [0.051], [21607.53], [0.000],
[A posteriori], [Strikt    ], [341.691], [157], [0.919], [0.057], [21567.04], [0.000],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Fit Indices der Messinvarianzanalyse.
]), 
kind: "quarto-float-tbl", 
supplement: "Tabelle", 
)
<tbl-mgcfa-ff3>


Die Ergebnisse dieser Messinvarianzanalyse in @tbl-mgcfa-ff3 können als Evidenz für die Annahme metrischer Skaleninvarianz (gleiche Item-Intercepts) interpretiert werden. Die Items wiesen also vorliegend die gleichen Ladungen auf, unabhängig davon, ob nach einer professionellen Lehrperson oder einer professionellen Lehrperson in der Deutsch-Fachdidaktik (Sprache) gefragt wurde, jedoch unterschiedliche Intercepts und Residualvarianen.

== Diskussion (8K)
<diskussion-8k>
Die vorliegende Arbeit hat drei zentrale Ergebnisse: Erstens enthalten offene Antworten von Lehrkräten auf die Frage, was »Professionalität« in der Deutsch-Fachdidaktik (Sprache) bzw. im Allgemeinen ausmacht, unter anderem auch die Ideen bildungswissenschaftlicher Professionalitätsansätze (strukturtheoretischer, metareflektiver, kompetenzorientierter und berufsbiographischer Ansatz). Zweitens konnte im Instrument mit geschlossenen Items zur Erfassung von Professionalitätsüberzeugungen von Cramer at al. #cite(<cramer2023>, form: "year") der Ausschluss einer eindimensionalen und einer a priori Struktur (vier Faktoren für strukturtheoretischen, metareflektiven, kompetenzorientierten und berufsbiographischen Ansatz) repliziert werden. Die von Cramer at al. #cite(<cramer2023>, form: "year") explorativ gefundene Struktur zeigte die vergleichsweise besten Fit-Indizes, die jedoch unter den klassischen Benchmarks für akzeptable oder gute Modellpassungen liegen @mcneish2021. Drittens zeigen offen wie geschlossen erfasste Profesionalitätsüberzeugungen sowohl Aspekte von Domänenspezifität als auch von Domänengeneralität: So sind etwa die offenen Antworten auf den globalen Stimulus (#emph[Wir interessieren uns nun dafür, was Ihrer Ansicht nach »Professionalität« einer Lehrperson ausmacht];) im Durchschnitt etwas Ähnlicher zu den geschlossenen Items als die Antworten die auf der fachdidaktik-spezifischen Stimulus folgen.

= Anhang
<anhang>
=== Wortlaut der Items
<sec-wortlaut-der-items>
==== Offene Items
<offene-items>
- Wir interessieren uns nun dafür, was Ihrer Ansicht nach »Professionalität« in der Deutsch-Fachdidaktik (Sprache) ausmacht. Bitte antworten Sie in ganzen Sätzen um Missverständnisse zu vermeiden und formulieren Sie möglichst drei Aspekte. Eine »professionelle« Lehrperson in der Deutsch-Fachdidaktik (Sprache) …
- Wir interessieren uns nun dafür, was Ihrer Ansicht nach »Professionalität« einer Lehrperson ausmacht. Bitte antworten Sie in ganzen Sätzen um Missverständnisse zu vermeiden und formulieren Sie möglichst drei Aspekte. Eine »professionelle« Lehrperson …

==== Geschlossene Items
<sec-geschlossene-items>
siehe XXX

#bibliography("references.bib")

