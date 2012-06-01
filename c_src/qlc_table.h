#ifndef QLC_TABLE_H
#define QLC_TABLE_H

#include "param_decoder.h"
#include "param_decoder_controller.h"

#include <xapian.h>
#include <string>
#include <cstring>
#include "termiter_gen.h"

#include "xapian_config.h"
XAPIAN_ERLANG_NS_BEGIN

class Driver;
class ResultEncoder;

class QlcType
{
public:
    enum QlcValidObjectType
    {
        MSET            = 0,
        TERMS           = 1,
        SPY_TERMS       = 2
    };
};

class QlcTable
{

    protected:
    Driver& m_driver;

    public:
    // Flags, that signal about end of list.
    static const uint8_t MORE = 1, STOP = 0;
    static const uint8_t UNKNOWN_SIZE = 0, KNOWN_SIZE = 1;

    QlcTable(Driver& driver);

    virtual
    ~QlcTable();
    
    virtual uint32_t
    numOfObjects() = 0;

    virtual void
    getPage(ResultEncoder&, uint32_t from, uint32_t count) = 0;

    virtual void
    lookup(PR) = 0;
};


class MSetQlcTable : public QlcTable
{
    Xapian::MSet m_mset;
    const ParamDecoderController m_controller;

    public:
    MSetQlcTable(Driver& driver, 
        Xapian::MSet& mset, const ParamDecoderController& controller);

    uint32_t numOfObjects();

    void getPage(ResultEncoder&, uint32_t from, uint32_t count);

    void lookup(PR);
};


class TermQlcTable : public QlcTable
{
    // Don't change m_end value
    Xapian::TermIterator m_iter, m_end;
    TermIteratorGenerator* mp_gen;
    uint32_t m_current_pos, m_size;
    
    const ParamDecoderController m_controller;
                     
    public:

    /**
     * gen variable will be deallocated by system (not a programmer!).
     */
    TermQlcTable(Driver& driver, 
        TermIteratorGenerator* gen, 
        const ParamDecoderController& controller);

    
    ~TermQlcTable() 
    {
        delete mp_gen;
    }

    /**
     * Return zero if unknown.
     */
    uint32_t numOfObjects();

    void getPage(ResultEncoder&, uint32_t from, uint32_t count);

    void lookup(PR);

    // Helpers
    private:
    void goToAndCheckBorder(const uint32_t skip);
    void goTo(const uint32_t skip);
    void getPageKnownSize(
            ResultEncoder&, const uint32_t skip, const uint32_t count);
    void getPageUnknownSize(
            ResultEncoder&, const uint32_t skip, const uint32_t count);
};

XAPIAN_ERLANG_NS_END
#endif
