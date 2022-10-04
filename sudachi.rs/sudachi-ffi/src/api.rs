use std::ops::Deref;
use std::path::PathBuf;
use sudachi::analysis::stateful_tokenizer::StatefulTokenizer;
use sudachi::config::Config;
use sudachi::dic::dictionary::JapaneseDictionary;
use sudachi::dic::subset::InfoSubset;
use sudachi::prelude::*;

#[allow(unused)]
fn consume_mlist<'a, 'b: 'a>(
    mlist: &'a MorphemeList<&'b JapaneseDictionary>,
    mlist2: &'a mut MorphemeList<&'b JapaneseDictionary>,
    data: &'a mut String,
) {
    if mlist.is_empty() {
        return;
    }

    // mlist.get_internal_cost() as isize;
    // use black_box function to forbit optimizing accesses to API functions
    // this is important for fuzzing, we want to trigger any possible panics that can happen
    for i in 0..mlist.len() {
        let m = mlist.get(i);
        let surf = m.surface();
        data.push_str(surf.deref());
        m.begin();
        m.begin_c();
        m.end();
        m.end_c();
        m.word_id().word();
        m.word_id().dic();
        m.part_of_speech_id();
        m.part_of_speech();
        m.get_word_info().a_unit_split();
        m.get_word_info().b_unit_split();
        m.get_word_info().synonym_group_ids();
        m.get_word_info().dictionary_form();
        m.get_word_info().dictionary_form_word_id();
        m.get_word_info().reading_form();
        m.get_word_info().surface();
        m.get_word_info().normalized_form();

        mlist2.clear();
        if m.split_into(Mode::A, mlist2).is_err() {
            return;
        }
        let mut mlen = 0;
        for j in 0..mlist2.len() {
            let m1 = mlist2.get(j);
            let s1 = m1.surface();
            assert_eq!(&mlist.surface()[m1.begin()..m1.end()], s1.deref());
            mlen += (m1.end() - m1.begin());
            m1.begin();
            m1.begin_c();
            m1.end();
            m1.end_c();
            m1.word_id().word();
            m1.word_id().dic();
            m1.part_of_speech_id();
            m1.part_of_speech();
            m1.get_word_info().a_unit_split();
            m1.get_word_info().b_unit_split();
            m1.get_word_info().synonym_group_ids();
            m1.get_word_info().dictionary_form();
            m1.get_word_info().dictionary_form_word_id();
            m1.get_word_info().reading_form();
            m1.get_word_info().surface();
            m1.get_word_info().normalized_form();
        }
        if !mlist2.is_empty() {
            assert_eq!(surf.len(), mlen);
        }
    }
}

pub fn parse(data: String, config_path: String) -> Vec<Vec<String>> {
    let cfg = Config::new(Some(PathBuf::from(config_path)), None, None).unwrap();
    let ana = JapaneseDictionary::from_cfg(&cfg).unwrap();

    let mut st = StatefulTokenizer::create(&ana, false, Mode::B);
    let mut mlist = MorphemeList::empty(&ana);

    st.set_subset(InfoSubset::default());
    st.reset().push_str(&data);
    st.do_tokenize().unwrap();
    mlist.collect_results(&mut st).unwrap();

    let mut vecr = Vec::new();
    for i in 0..mlist.len() {
        let m = mlist.get(i);
        let winfo: [String; 6] = [
            m.begin_c().to_string(),
            m.end_c().to_string(),
            m.part_of_speech().deref()[0].clone(),
            String::from(m.surface().deref()),
            String::from(m.dictionary_form()),
            String::from(m.reading_form()),
        ];
        vecr.push(winfo.to_vec());
    }
    return vecr;
}
