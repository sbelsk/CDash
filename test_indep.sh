log_file=./indep_tests.log
rm $log_file

function run_test {
    if $test_command; then
        echo "test #$i passed" >> $log_file
    else
        echo "test #$i failed" >> $log_file
    fi
}

for i in $(seq 1 10); do
    echo " * * * * * * * RUNNING TEST: $i * * * * * * *"
    test_command="ctest -I ,,0,$i"
    run_test
done

for i in $(seq 12 71); do
    echo " * * * * * * * RUNNING TESTS: 11, $i, 72 * * * * * * *"
    test_command="ctest -I ,,0,11,$i,72"
    run_test
done

for i in $(seq 73 229); do
    echo " * * * * * * * RUNNING TESTS: 72, $i * * * * * * *"
    test_command="ctest -I ,,0,72,$i"
    run_test
done
