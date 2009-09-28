echo -n "LOC including documentation: "
find . -name "*.pm" | xargs cat | wc -l
echo -n "LOC without documentation:   "
find . -name "*.pm" | xargs cat | perl -e 'my $a = join "", <>; $a =~ s/^=.*?^=cut//msg; $a =~ s/^\s*#.*?$//msg; $a =~ s/^\s*//msg; print $a;' | wc -l
