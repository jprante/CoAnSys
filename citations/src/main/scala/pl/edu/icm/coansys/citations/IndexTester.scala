package pl.edu.icm.coansys.citations

import com.nicta.scoobi.application.ScoobiApp

/**
 * @author Mateusz Fedoryszak (m.fedoryszak@icm.edu.pl)
 */
object IndexTester extends ScoobiApp {
  override def upload = false

  def testIndex(indexUri: String, query: String) {
    val index = new AuthorIndex(indexUri)
    index.getDocumentsByAuthor(query).foreach(x => println(x.id))
  }

  def run() {
    if (args.length != 2) {
      println("Usage: IndexTester <index_path> <query>")
    } else {
      testIndex(args(0), args(1))
    }
  }
}
